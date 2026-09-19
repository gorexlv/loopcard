// Rendering fixtures only: these tests do not claim that a model generated or
// correctly explained the sample content. Live Q&A evidence is recorded by
// supabase/tests/card-agent/run_scenarios.py.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

class NoModelAgent implements CardAgent {
  @override
  String get owner => 'render-fixture';
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) =>
      throw StateError('No model responses are mocked in rendering tests');
}

void main() {
  final fixtures = [
    (
      type: '单词卡',
      prompt: 'borrow',
      preset: CardPreset.all.first,
      sections: const [
        CardBackSection(title: '释义', heading: '借入；借用', body: '暂时使用别人的东西，之后归还。'),
      ],
      expected: '借入；借用',
    ),
    (
      type: '诗词卡',
      prompt: '《静夜思》· 李白',
      preset: CardPreset.all.firstWhere((p) => p.id == 'poetry-overview'),
      sections: const [
        CardBackSection(
          title: '原诗',
          heading: '静夜思',
          body: '床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
        ),
        CardBackSection(title: '释义', heading: '思乡', body: '抬头望着明月，低头思念故乡。'),
      ],
      expected: '床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
    ),
    (
      type: '古文卡',
      prompt: '学而时习之，不亦说乎？',
      preset: CardPreset.all.firstWhere((p) => p.id == 'classical-translation'),
      sections: const [
        CardBackSection(
          title: '白话',
          heading: '学习与温习',
          body: '学习后按时温习，不也是令人愉快的吗？',
        ),
        CardBackSection(title: '字词', heading: '说', body: 'yuè，同“悦”，高兴、愉快。'),
      ],
      expected: 'yuè，同“悦”，高兴、愉快。',
    ),
  ];
  for (final f in fixtures) {
    testWidgets(
      '${f.type}: fixture renders both faces within chat, without a model call',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final draft = WordCardDraft(
          prompt: f.prompt,
          sections: f.sections,
          presentation: {...f.preset.rules, 'skill_version': '1'},
        );
        final state = {
          'id': 'fixture',
          'sources': [
            {'id': 'p1', 'text': f.prompt},
          ],
          'rules': f.preset.rules,
          'revision': 1,
          'messages': [
            {
              'role': 'assistant',
              'content': '渲染测试样本',
              'revision': 1,
              'cards': [draftToJson(draft)],
            },
          ],
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: LoopTheme.light,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: CardAgentScreen(
              agent: NoModelAgent(),
              store: AgentSessionStore(f.type),
              sources: const [],
              restored: state,
              onSave: (_, _, _) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(f.prompt), findsOneWidget);
        await tester.tap(find.text('查看背面'));
        await tester.pumpAndSettle();
        expect(find.text(f.expected), findsOneWidget);
        expect(find.text('当前草稿 · 尚未保存'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
