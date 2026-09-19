import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/splash_screen.dart';
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

  Widget app({
    bool reduceMotion = false,
    Locale locale = const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
    ),
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: LoopTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: SplashScreen(onFinished: () {}, duration: const Duration(hours: 1)),
  );

  testWidgets('splash tells the memory-loop story with a card stack', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF313153),
    );
    expect(find.byKey(const ValueKey('splash-paper-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-loop-trace')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash-card-stack')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('splash-memory-sheet-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('splash-memory-sheet-middle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('splash-memory-sheet-front')),
      findsOneWidget,
    );

    final initialStack = tester.widget<Opacity>(
      find.byKey(const ValueKey('splash-stack-opacity')),
    );
    expect(initialStack.opacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 1250));
    final settledStack = tester.widget<Opacity>(
      find.byKey(const ValueKey('splash-stack-opacity')),
    );
    expect(settledStack.opacity, 1);
    expect(find.text('LoopCard'), findsOneWidget);
    expect(find.text('让记忆，循环发生'), findsOneWidget);
  });

  testWidgets('reduced motion renders the completed composition immediately', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump();

    final stack = tester.widget<Opacity>(
      find.byKey(const ValueKey('splash-stack-opacity')),
    );
    final copy = tester.widget<Opacity>(
      find.byKey(const ValueKey('splash-copy-opacity')),
    );
    expect(stack.opacity, 1);
    expect(copy.opacity, 1);
  });

  testWidgets('matches the completed splash composition', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(reduceMotion: true));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/brand/loopcard-app-icon.png'),
        tester.element(find.byType(SplashScreen)),
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('design-canvas')),
      matchesGoldenFile('goldens/08-splash.png'),
    );
  });

  testWidgets('keeps long translated taglines on a single line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(reduceMotion: true, locale: const Locale('es')),
    );
    await tester.pump();

    expect(
      tester.getSize(find.text('Haz que la memoria se repita')).height,
      lessThanOrEqualTo(24),
    );
    expect(tester.takeException(), isNull);
  });
}
