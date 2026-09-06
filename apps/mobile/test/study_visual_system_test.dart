import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  Widget app() => MaterialApp(
    locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: LoopTheme.dark,
    home: StudyScreen(deck: DemoData.problemDeck),
  );

  testWidgets('problem study reveals the answer and progressive sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('problem-composition')), findsOneWidget);
    expect(find.text('关键突破'), findsNothing);
    expect(find.text('门清儿'), findsNothing);

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();

    expect(find.text('关键突破'), findsWidgets);
    expect(find.text('门清儿'), findsOneWidget);

    await tester.tap(find.text('方法迁移'));
    await tester.pumpAndSettle();

    expect(find.textContaining('总量 ÷ 份数'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
