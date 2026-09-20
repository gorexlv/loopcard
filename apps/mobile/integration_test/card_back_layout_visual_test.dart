import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import '../test/fixtures/card_back_samples.dart';

class _VisualAgent implements CardAgent {
  @override
  String get owner => 'minimal-ui-visual';
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async =>
      throw StateError('Rendering fixture only');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('card backs on native screens in both themes and large text', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      for (final entry in [
        ('word', DemoData.wordDeck.cards.first, 1.0),
        ('poem', alignedPoem, 1.0),
        ('ci', stanzaPoem, 1.0),
        ('large-word', longWordBack, 2.0),
      ]) {
        final (name, card, scale) = entry;
        await tester.pumpWidget(
          MaterialApp(
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
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: StudyScreen(
              deck: CardDeck(
                id: name,
                title: name,
                subtitle: '',
                kind: card.presentation['skill'] == 'poetry'
                    ? CardKind.problem
                    : CardKind.word,
                cards: [card],
                mastered: 0,
                fuzzy: 0,
                forgotten: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(EditorialCard));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('${dark ? 'dark' : 'light'}-$name-back');
        if (name == 'ci') {
          await tester.tap(find.text('下阕'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('${dark ? 'dark' : 'light'}-ci-lower');
        }
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('quiet card generation screen', (tester) async {
    final word = DemoData.wordDeck.cards.first;
    final rules = CardPreset.all.first.rules;
    await tester.pumpWidget(
      MaterialApp(
        theme: LoopTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CardAgentScreen(
          agent: _VisualAgent(),
          store: AgentSessionStore('minimal-ui-visual'),
          sources: const [],
          onSave: (_, _, _) async {},
          restored: {
            'id': 'minimal-ui-visual',
            'sources': [
              {'id': 'p1', 'text': 'borrow'},
            ],
            'rules': rules,
            'revision': 1,
            'messages': [
              {
                'role': 'assistant',
                'revision': 1,
                'content': '已按「简洁单词」生成草稿，可以翻面检查，也可以继续告诉我如何调整。',
                'rules': rules,
                'cards': [
                  draftToJson(
                    WordCardDraft(
                      prompt: word.prompt,
                      sections: word.sections,
                      wordContent: word.wordContent,
                      presentation: rules,
                    ),
                  ),
                ],
              },
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看背面'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('light-generation-back');
    expect(find.textContaining('已按「简洁单词」'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
