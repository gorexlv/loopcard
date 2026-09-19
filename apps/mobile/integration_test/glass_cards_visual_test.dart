import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

class PreviewOnlyAgent implements CardAgent {
  @override
  String get owner => 'glass-visual';
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async =>
      throw StateError('Visual fixture only');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('shared glass material on study and chat in light and dark', (
    tester,
  ) async {
    Widget app(Widget screen, bool dark) => MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: dark ? LoopTheme.dark : LoopTheme.light,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    );
    for (final dark in [true, false]) {
      final mode = dark ? 'dark' : 'light';
      await tester.pumpWidget(
        app(StudyScreen(deck: DemoData.wordDeck, readOnly: true), dark),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('$mode-study-front');
      await tester.tap(find.text('borrow'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('$mode-study-back');
      final rules = CardPreset.all
          .firstWhere((p) => p.id == 'poetry-overview')
          .rules;
      await tester.pumpWidget(
        app(
          CardAgentScreen(
            agent: PreviewOnlyAgent(),
            store: AgentSessionStore('glass-$mode'),
            sources: const [],
            onSave: (_, _, _) async {},
            restored: {
              'id': 'glass-$mode',
              'sources': [
                {'id': 'p1', 'text': '静夜思'},
              ],
              'rules': rules,
              'revision': 1,
              'messages': [
                {
                  'role': 'assistant',
                  'content': '已应用「诗词全篇」。翻面查看原文和释义。',
                  'example': true,
                  'cards': [
                    {
                      'prompt': '静夜思',
                      'hint': '李白 · 唐',
                      'presentation': {...rules, 'skill_version': '1'},
                      'sections': [
                        {
                          'title': '原文',
                          'heading': '',
                          'body': '床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
                        },
                        {
                          'title': '白话释义',
                          'heading': '思念故乡',
                          'body': '明月引起了对故乡的思念。',
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ),
          dark,
        ),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('$mode-chat-front');
      await tester.tap(find.text('查看背面'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('$mode-chat-back');
      expect(tester.takeException(), isNull);
    }
  });
}
