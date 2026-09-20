import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

Widget app(Widget child) => MaterialApp(
  theme: LoopTheme.light,
  locale: const Locale('zh'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'session store isolates accounts and round trips presentation',
    () async {
      final owner = AgentSessionStore('owner');
      final other = AgentSessionStore('other');
      await owner.save({
        'rules': CardPreset.all.first.rules,
        'messages': [
          {
            'role': 'assistant',
            'cards': [
              {
                'presentation': {'layout': 'centered'},
              },
            ],
          },
        ],
      });
      expect(await other.load(), isNull);
      expect(
        (await owner
            .load())!['messages'][0]['cards'][0]['presentation']['layout'],
        'centered',
      );
    },
  );
  testWidgets('preset renders both faces inline without calling provider', (
    tester,
  ) async {
    final agent = FakeAgent();
    await tester.pumpWidget(
      app(
        CardAgentScreen(
          agent: agent,
          store: AgentSessionStore('owner'),
          sources: const [
            {'id': '1', 'text': 'borrow lend'},
          ],
          onSave: (_, _, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('简洁单词').first);
    await tester.pumpAndSettle();
    expect(agent.calls, 0);
    await tester.scrollUntilVisible(
      find.text('查看背面'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(EditorialCard), findsOneWidget);
    await tester.tap(find.text('查看背面'));
    await tester.pumpAndSettle();
    expect(find.text('This is an example.'), findsOneWidget);
    final state = await AgentSessionStore('owner').load();
    expect(state!['messages'].last['example'], isTrue);
    expect(tester.takeException(), isNull);
  });
  for (final preset in CardPreset.all.where(
    (p) => p.skill == 'poetry' || p.skill == 'classical',
  )) {
    testWidgets(
      '${preset.id} selection shows an inline example and persists rules',
      (tester) async {
        final agent = FakeAgent();
        final store = AgentSessionStore('literary');
        await tester.pumpWidget(
          app(
            CardAgentScreen(
              agent: agent,
              store: store,
              sources: const [
                {'id': 'p1', 'text': '学而时习之，不亦说乎？'},
              ],
              onSave: (_, _, _) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining(preset.name).first,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.textContaining(preset.name).first),
          alignment: 0.2,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining(preset.name).first);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('查看背面'),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('查看背面')),
          alignment: 0.4,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('查看背面'));
        await tester.pumpAndSettle();
        expect(find.text('查看正面'), findsOneWidget);
        expect(find.byType(EditorialCard), findsOneWidget);
        expect(agent.calls, 0);
        final state = (await store.load())!;
        expect(state['rules']['preset'], preset.id);
        expect(state['rules']['skill'], preset.skill);
        expect(state['messages'].last['example'], isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('real drafts survive restore and save requires confirmation', (
    tester,
  ) async {
    final agent = FakeAgent();
    var saves = 0;
    final store = AgentSessionStore('owner');
    Widget screen({Map<String, dynamic>? restored}) => CardAgentScreen(
      agent: agent,
      store: store,
      sources: const [
        {'id': '1', 'text': 'Water evaporates.'},
      ],
      restored: restored,
      onSave: (_, _, cards) async {
        saves++;
        expect(cards.first.presentation['session_id'], isNotEmpty);
      },
    );
    await tester.pumpWidget(app(screen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('生成卡片'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成卡片'));
    await tester.pumpAndSettle();
    expect(agent.calls, 1);
    expect(saves, 0);
    expect(find.text('保存'), findsOneWidget);
    final state = await store.load();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(screen(restored: state)));
    await tester.pumpAndSettle();
    expect(find.text('保存'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect((await store.load())!['saved'], isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'editing updates only current draft and changing presets preserves history',
    (tester) async {
      final rules = CardPreset.all.first.rules;
      final store = AgentSessionStore('owner');
      final initial = {
        'id': 'session',
        'sources': [
          {'id': '1', 'text': 'borrow'},
        ],
        'rules': rules,
        'revision': 1,
        'messages': [
          {
            'role': 'assistant',
            'content': '草稿已生成',
            'rules': rules,
            'revision': 1,
            'cards': [
              draftToJson(
                WordCardDraft(
                  prompt: 'borrow',
                  sections: const [
                    CardBackSection(title: '释义', heading: '借用', body: '使用后归还'),
                  ],
                  presentation: {
                    ...rules,
                    'session_id': 'session',
                    'skill_version': '1',
                  },
                ),
              ),
            ],
          },
        ],
      };
      await tester.pumpWidget(
        app(
          CardAgentScreen(
            agent: FakeAgent(),
            store: store,
            sources: const [],
            restored: initial,
            onSave: (_, _, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('编辑'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'borrow something');
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(
        (await store.load())!['messages'][0]['cards'][0]['prompt'],
        'borrow something',
      );
      await tester.ensureVisible(find.text('排版'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('排版'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('知识问答').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('知识问答').first);
      await tester.pumpAndSettle();
      final stored = (await store.load())!;
      expect(stored['messages'][0]['cards'][0]['prompt'], 'borrow something');
      expect(stored['rules']['skill'], 'knowledge');
      expect(find.text('保存'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'conversation preview is inline and cannot save an incomplete batch',
    (tester) async {
      final agent = FakeAgent()..previewChat = true;
      final store = AgentSessionStore('owner');
      await tester.pumpWidget(
        app(
          CardAgentScreen(
            agent: agent,
            store: store,
            sources: const [
              {'id': '1', 'text': 'borrow'},
            ],
            onSave: (_, _, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '背面先显示例句');
      await tester.tap(find.byTooltip('发送'));
      await tester.pumpAndSettle();
      final result = (await store.load())!['messages'].last;
      expect(result['preview'], isTrue);
      expect(result['cards'], hasLength(1));
      expect(find.text('保存'), findsNothing);
      expect(find.text('预览'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed request retains conversation and retries same request', (
    tester,
  ) async {
    final agent = FakeAgent()..fail = true;
    await tester.pumpWidget(
      app(
        CardAgentScreen(
          agent: agent,
          store: AgentSessionStore('owner'),
          sources: const [
            {'id': '1', 'text': 'borrow'},
          ],
          onSave: (_, _, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '背面用中文');
    await tester.tap(find.byTooltip('发送'));
    await tester.pumpAndSettle();
    expect(find.text('重试'), findsOneWidget);
    final pending = (await AgentSessionStore('owner').load())!['pending'];
    expect(pending['messages'].last['content'], '背面用中文');
    agent.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(agent.calls, 2);
    expect((await AgentSessionStore('owner').load())!['pending'], isNull);
    expect(tester.takeException(), isNull);
  });
}

class FakeAgent implements CardAgent {
  int calls = 0;
  bool fail = false;
  bool previewChat = false;
  @override
  String get owner => 'owner';
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    calls++;
    if (fail) throw StateError('offline');
    return {
      'reply': '已按你的要求处理。',
      'rules': request['rules'],
      'cards': request['action'] == 'chat' && !previewChat
          ? []
          : [
              draftToJson(
                WordCardDraft(
                  prompt: 'borrow',
                  hint: '',
                  sections: const [
                    CardBackSection(
                      title: '释义',
                      heading: '借用',
                      body: '暂时使用后归还。',
                    ),
                  ],
                  presentation: {
                    ...Map<String, dynamic>.from(request['rules']),
                    'skill_version': '1',
                    'source_ids': ['1'],
                  },
                ),
              ),
            ],
    };
  }
}
