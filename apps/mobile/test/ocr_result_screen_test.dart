import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/ocr_result_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import 'package:loopcard/widgets/glass_surface.dart';

void main() {
  testWidgets('selects every recognized word by default and updates count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LoopTheme.data,
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
        home: const OcrResultScreen(words: ['borrow', 'lend']),
      ),
    );

    expect(find.text('识别结果'), findsOneWidget);
    expect(find.text('已选择 2 个单词'), findsOneWidget);
    expect(find.byKey(const ValueKey('recognized-word-list')), findsOneWidget);
    expect(find.byType(GlassSurface), findsNothing);
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((box) => box.value),
      everyElement(isTrue),
    );

    await tester.tap(find.text('borrow'));
    await tester.pump();

    expect(find.text('已选择 1 个单词'), findsOneWidget);
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((box) => box.value),
      [false, true],
    );
  });

  testWidgets('returns selected words when confirmed', (tester) async {
    List<String>? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        theme: LoopTheme.data,
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
        home: OcrResultScreen(
          words: const ['borrow', 'lend'],
          onConfirm: (words) => confirmed = words,
        ),
      ),
    );

    await tester.tap(find.text('lend'));
    await tester.pump();
    await tester.tap(find.text('确认选择'));
    await tester.pump();

    expect(confirmed, ['borrow']);
  });

  testWidgets('caps a generation batch at thirty words', (tester) async {
    List<String>? confirmed;
    final words = List.generate(35, (index) => 'word$index');
    await tester.pumpWidget(
      MaterialApp(
        theme: LoopTheme.data,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: OcrResultScreen(
          words: words,
          onConfirm: (value) => confirmed = value,
        ),
      ),
    );

    await tester.tap(find.text('Confirm selection'));
    await tester.pump();
    expect(confirmed, hasLength(30));
  });
}
