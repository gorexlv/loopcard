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
import 'package:loopcard/screens/result_screen.dart';
import 'package:loopcard/screens/splash_screen.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    final noto = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf'));
    await Future.wait([inter.load(), noto.load()]);
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

    await tester.tap(find.text('borrow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('例句搭配'));
    await tester.pumpAndSettle();
    await capture(tester, '04-card-back');

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

    final attempts = DemoData.wordDeck.cards
        .map(
          (card) => CardAttempt(
            cardId: card.id,
            prompt: card.prompt,
            familiarity: Familiarity.mastered,
          ),
        )
        .toList();
    await tester.pumpWidget(
      testApp(ResultScreen(deck: DemoData.wordDeck, attempts: attempts)),
    );
    await tester.pumpAndSettle();
    await capture(tester, '05-result');
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
