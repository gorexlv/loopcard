import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/auth/auth_service.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/login_screen.dart';
import 'package:loopcard/screens/onboarding_screen.dart';
import 'package:loopcard/screens/deck_detail_screen.dart';
import 'package:loopcard/screens/ocr_result_screen.dart';
import 'package:loopcard/screens/word_draft_review_screen.dart';
import 'package:loopcard/screens/card_studio_screen.dart';
import 'package:loopcard/screens/photo_batch_screen.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/screens/home_screen.dart';
import 'package:loopcard/screens/decks_screen.dart';
import 'package:loopcard/screens/profile_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import 'package:loopcard/widgets/brand_lockup.dart';
import 'card_agent_screen_test.dart' show FakeAgent;
import 'photo_batch_screen_test.dart' show FakePhotoFlow;

const draft = WordCardDraft(
  prompt: 'borrow',
  sections: [
    CardBackSection(title: 'Meaning', heading: '借用', body: 'Use and return.'),
  ],
);

Widget app(Widget child) => MaterialApp(
  theme: LoopTheme.dark,
  locale: const Locale('zh'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.3)),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final pages = <String, Widget Function()>{
    'home': () => HomeScreen(decks: DemoData.decks),
    'decks': () => DecksScreen(decks: DemoData.decks),
    'profile': () => ProfileScreen(
      decks: DemoData.decks,
      user: const AppUser(
        id: 'layout',
        displayName: 'A very long account display name',
        email: 'long.email.address@example.com',
      ),
      onSignOut: () async {},
      locale: const Locale('zh'),
      themeMode: ThemeMode.dark,
      onLocaleChanged: (_) {},
      onThemeModeChanged: (_) {},
    ),
    'login': () => LoginScreen(authService: MemoryAuthService()),
    'onboarding': () => OnboardingScreen(onComplete: (_) async {}),
    'deck': () => DeckDetailScreen(deck: DemoData.decks.first),
    'ocr': () => OcrResultScreen(words: List.generate(50, (i) => 'word $i')),
    'drafts': () => WordDraftReviewScreen(
      initialDeckTitle: 'Draft',
      loadDrafts: () async => [draft],
      onSave: (_, _) async {},
    ),
    'studio': () => CardStudioScreen(
      card: DemoData.decks.first.cards.first,
      kind: DemoData.decks.first.kind,
    ),
    'photos': () => PhotoBatchScreen(flow: FakePhotoFlow()),
    'agent': () => CardAgentScreen(
      agent: FakeAgent(),
      store: AgentSessionStore('layout'),
      sources: const [
        {'id': '1', 'text': 'borrow'},
      ],
      onSave: (_, _, _) async {},
    ),
  };
  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(834, 1194),
  ]) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} fits $size with safe insets and larger text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(entry.value()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final back = find.byKey(const ValueKey('page-back'));
        if (back.evaluate().isNotEmpty) {
          expect(tester.getTopLeft(back).dy, greaterThanOrEqualTo(47));
          expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
        }
        // Scroll the main content to expose long forms and trailing controls.
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -900));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('all onboarding steps remain reachable on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var completed = false;
    await tester.pumpWidget(
      app(OnboardingScreen(onComplete: (_) async => completed = true)),
    );
    await tester.pumpAndSettle();
    final brand = tester.getRect(find.byType(BrandLockup));
    for (var step = 0; step < 3; step++) {
      final next = find.text('继续');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(BrandLockup)), brand);
    }
    final start = find.widgetWithText(
      FilledButton,
      tester.element(find.byType(OnboardingScreen)).l10n.tr('getStarted'),
    );
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    expect(completed, isTrue);
  });

  testWidgets('draft title and save remain accessible above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(pages['drafts']!()));
    await tester.pumpAndSettle();
    final back = tester.getRect(find.byKey(const ValueKey('page-back')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    final title = find.byKey(const ValueKey('captured-deck-title'));
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.enterText(title, 'Updated title');
    expect(tester.getBottomLeft(title).dy, lessThan(328));
    expect(
      tester
          .getBottomLeft(find.byKey(const ValueKey('save-generated-cards')))
          .dy,
      lessThanOrEqualTo(328),
    );
    expect(tester.getRect(find.byKey(const ValueKey('page-back'))), back);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared back control pops a secondary route', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OcrResultScreen(words: ['borrow']),
                ),
              ),
              child: const Text('Open OCR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open OCR'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('page-back')));
    await tester.pumpAndSettle();
    expect(find.text('Open OCR'), findsOneWidget);
    expect(find.byType(OcrResultScreen), findsNothing);
  });

  testWidgets('authentication and main tabs share brand position and size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Rect? brand;
    for (final page in [
      LoginScreen(authService: MemoryAuthService()),
      OnboardingScreen(onComplete: (_) async {}),
      HomeScreen(decks: DemoData.decks),
    ]) {
      await tester.pumpWidget(app(page));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(BrandLockup));
      brand ??= rect;
      expect(rect, brand);
    }
  });
}
