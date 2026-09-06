import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/ocr_result_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

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
}
