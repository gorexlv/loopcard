import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/auth/auth_service.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/deck_detail_screen.dart';
import 'package:loopcard/screens/card_studio_screen.dart';
import 'package:loopcard/screens/decks_screen.dart';
import 'package:loopcard/screens/home_screen.dart';
import 'package:loopcard/screens/profile_screen.dart';
import 'package:loopcard/screens/onboarding_screen.dart';
import 'package:loopcard/screens/ocr_result_screen.dart';
import 'package:loopcard/screens/result_screen.dart';
import 'package:loopcard/screens/splash_screen.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/screens/word_draft_review_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    final noto = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf'));
    final newsreader = FontLoader('Newsreader')
      ..addFont(rootBundle.load('assets/fonts/Newsreader-Variable.ttf'));
    await Future.wait([inter.load(), noto.load(), newsreader.load()]);
  });

  Widget testApp(Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: LoopTheme.dark,
    home: home,
  );

  Future<void> prepare(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(testApp(home));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/loopcard-app-icon.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await expectLater(
      find.byKey(const ValueKey('design-canvas')),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('captures the primary mobile flow', (tester) async {
    await prepare(tester, HomeScreen(decks: DemoData.decks));
    await capture(tester, '01-home');

    await tester.pumpWidget(testApp(DecksScreen(decks: DemoData.decks)));
    await tester.pumpAndSettle();
    await capture(tester, '06-decks');

    await tester.pumpWidget(
      testApp(
        ProfileScreen(
          decks: DemoData.decks,
          user: const AppUser(id: 'golden', email: 'user@loopcard.test'),
          onSignOut: () async {},
          locale: const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
          ),
          themeMode: ThemeMode.dark,
          onLocaleChanged: (_) {},
          onThemeModeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, '07-profile');

    await tester.pumpWidget(testApp(DeckDetailScreen(deck: DemoData.wordDeck)));
    await tester.pumpAndSettle();
    await capture(tester, '02-deck-detail');

    await tester.pumpWidget(testApp(StudyScreen(deck: DemoData.wordDeck)));
    await tester.pumpAndSettle();
    await capture(tester, '03-card-front');

    await tester.pumpWidget(
      testApp(
        StudyScreen(
          deck: CardDeck(
            id: 'long-word',
            title: 'Long word',
            subtitle: '',
            kind: CardKind.word,
            cards: const [
              StudyCard(
                id: 'characteristically',
                prompt: 'characteristically',
                hint: 'Think of something done in a typical way.',
                sections: [
                  CardBackSection(
                    title: 'Meaning',
                    heading: '典型地',
                    body: '以某人或某物典型的方式。',
                  ),
                ],
                wordContent: WordCardContent(
                  partOfSpeech: 'adv.',
                  pronunciations: [
                    WordPronunciation(ipa: '/ˌkærəktəˈrɪstɪkli/'),
                  ],
                  definition: '典型地',
                  example: WordExample(
                    sentence: 'She was characteristically calm.',
                    translation: '她一如既往地冷静。',
                  ),
                ),
              ),
            ],
            mastered: 0,
            fuzzy: 0,
            forgotten: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, '19-long-word-front');

    await tester.pumpWidget(testApp(StudyScreen(deck: DemoData.wordDeck)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('borrow'));
    await tester.pumpAndSettle();
    await capture(tester, '04-card-back');
    await tester.tap(find.byKey(const ValueKey('next-back-section')));
    await tester.pumpAndSettle();
    await capture(tester, '18-card-back-usage');

    await tester.pumpWidget(testApp(StudyScreen(deck: DemoData.formulaDeck)));
    await tester.pumpAndSettle();
    await capture(tester, '12-formula-card-front');

    await tester.pumpWidget(testApp(StudyScreen(deck: DemoData.problemDeck)));
    await tester.pumpAndSettle();
    await capture(tester, '13-problem-card-front');
    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    await capture(tester, '14-problem-card-back');

    await tester.pumpWidget(
      testApp(
        CardStudioScreen(
          card: DemoData.wordDeck.cards.first,
          kind: DemoData.wordDeck.kind,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, '15-card-studio');

    final attempts = DemoData.wordDeck.cards.indexed
        .map(
          (entry) => CardAttempt(
            cardId: entry.$2.id,
            prompt: entry.$2.prompt,
            familiarity: entry.$1 < 12
                ? Familiarity.mastered
                : entry.$1 < 17
                ? Familiarity.fuzzy
                : Familiarity.forgotten,
          ),
        )
        .toList();
    await tester.pumpWidget(
      testApp(ResultScreen(deck: DemoData.wordDeck, attempts: attempts)),
    );
    await tester.pumpAndSettle();
    await capture(tester, '05-result');

    await tester.pumpWidget(
      testApp(
        WordDraftReviewScreen(
          initialDeckTitle: 'Captured words',
          loadDrafts: () async => const [
            WordCardDraft(
              prompt: 'borrow',
              sections: [
                CardBackSection(
                  title: 'Meaning',
                  heading: 'v. 借入；借用',
                  body: '暂时使用某物，并打算随后归还。',
                ),
                CardBackSection(
                  title: 'Example & collocation',
                  heading: 'borrow a book',
                  body: 'May I borrow this book for the weekend?',
                ),
                CardBackSection(
                  title: 'Common confusion',
                  heading: 'borrow 与 lend',
                  body: 'borrow 表示借入，lend 表示借出。',
                ),
              ],
            ),
          ],
          onSave: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, '16-word-draft-review');

    await tester.pumpWidget(
      testApp(
        const OcrResultScreen(
          words: [
            'oobl',
            'Unit',
            'fly',
            'flag',
            'globe',
            'glass',
            'Listen',
            'point',
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final word in ['oobl', 'Unit', 'Listen', 'point']) {
      await tester.tap(find.text(word));
    }
    await tester.pumpAndSettle();
    await capture(tester, '17-ocr-results');
  });

  testWidgets('captures brand and onboarding states', (tester) async {
    await prepare(
      tester,
      SplashScreen(onFinished: () {}, duration: const Duration(hours: 1)),
    );
    await tester.pump(const Duration(milliseconds: 1250));
    await capture(tester, '08-splash');

    await prepare(tester, OnboardingScreen(onComplete: (answers) async {}));
    await capture(tester, '09-onboarding-stage');

    for (var index = 0; index < 3; index += 1) {
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
    }
    await capture(tester, '10-onboarding-ready');
  });

  testWidgets('captures the overseas English light theme', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: LoopTheme.light,
        home: HomeScreen(decks: DemoData.decks),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, '11-home-en-light');
  });
}
