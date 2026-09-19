import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/main.dart';
import 'package:loopcard/widgets/brand_lockup.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/decks_screen.dart';
import 'package:loopcard/screens/home_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
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

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(834, 1194),
    const Size(1194, 834),
  ]) {
    testWidgets('primary tabs keep brand geometry at $size with safe insets', (
      tester,
    ) async {
      await setSize(tester, size);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(const LoopCardApp());
      await tester.pumpAndSettle();
      final brand = find.byType(BrandLockup);
      final initial = tester.getRect(brand);
      expect(initial.top, greaterThanOrEqualTo(47));
      for (final tab in ['decks', 'profile', 'learn']) {
        await tester.tap(find.byKey(ValueKey('primary-nav-$tab')));
        await tester.pumpAndSettle();
        expect(tester.getRect(brand), initial);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('primary-nav-profile')));
      await tester.pumpAndSettle();
      final list = find.byType(ListView);
      await tester.drag(list, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getRect(brand), initial);
      final about = find.text('关于 LoopCard');
      expect(about, findsOneWidget);
      expect(
        tester.getBottomLeft(about).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('primary-navigation-dock')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'primary pages fill the iPad viewport without scaling the canvas',
    (tester) async {
      const size = Size(834, 1194);
      await setSize(tester, size);
      await tester.pumpWidget(testApp(HomeScreen(decks: DemoData.decks)));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const ValueKey('design-canvas-content'))),
        size,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deck grid stays above navigation on iPad portrait', (
    tester,
  ) async {
    await setSize(tester, const Size(834, 1194));
    await tester.pumpWidget(testApp(DecksScreen(decks: DemoData.decks)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-grid')), findsOneWidget);
    final gridBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('deck-grid')))
        .dy;
    for (final title in ['日常英语词汇', '常见化学式', '思维解题卡']) {
      expect(tester.getBottomLeft(find.text(title)).dy, lessThan(gridBottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('deck grid supports iPad landscape', (tester) async {
    await setSize(tester, const Size(1194, 834));
    await tester.pumpWidget(testApp(DecksScreen(decks: DemoData.decks)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('deck-grid')), findsOneWidget);
    expect(find.text('思维解题卡'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
