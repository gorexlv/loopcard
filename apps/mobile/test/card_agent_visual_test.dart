import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import 'card_agent_screen_test.dart' show FakeAgent;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'NotoSansSC',
    )..addFont(rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf'))).load();
  });
  testWidgets('chat renders card faces on a phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rules = CardPreset.all.first.rules;
    final session = {
      'id': '12345678-1234-4234-8234-123456789abc',
      'sources': [
        {'id': 'photo1', 'text': 'borrow'},
      ],
      'rules': rules,
      'revision': 2,
      'messages': [
        {
          'role': 'assistant',
          'content': '已按「简洁单词」生成草稿，可以翻面检查，也可以继续告诉我如何调整。',
          'revision': 2,
          'rules': rules,
          'cards': [
            {
              'prompt': 'borrow',
              'hint': '/ˈbɒrəʊ/ · v.',
              'presentation': {
                ...rules,
                'session_id': '12345678-1234-4234-8234-123456789abc',
                'skill_version': '1',
              },
              'sections': [
                {'title': '释义', 'heading': '借入；借用', 'body': '暂时使用别人的东西，之后归还。'},
                {
                  'title': '例句',
                  'heading': 'May I borrow this book?',
                  'body': '我可以借这本书吗？',
                },
              ],
            },
          ],
        },
      ],
    };
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LoopTheme.dark,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RepaintBoundary(
          key: const ValueKey('agent-screen'),
          child: CardAgentScreen(
            agent: FakeAgent(),
            store: AgentSessionStore('visual'),
            sources: const [],
            restored: session,
            onSave: (_, _, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('已按「简洁单词」'), findsNothing);
    expect(find.textContaining('当前草稿'), findsNothing);
    expect(find.textContaining('正面：'), findsNothing);
    await expectLater(
      find.byKey(const ValueKey('agent-screen')),
      matchesGoldenFile('goldens/20-agent-chat-front.png'),
    );
    await tester.tap(find.text('查看背面'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('agent-screen')),
      matchesGoldenFile('goldens/21-agent-chat-back.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
