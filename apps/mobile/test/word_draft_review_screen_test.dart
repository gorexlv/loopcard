import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/word_draft_review_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: LoopTheme.dark,
    locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );

  const draft = WordCardDraft(
    prompt: 'borrow',
    sections: [
      CardBackSection(
        title: 'Meaning',
        heading: 'v. take temporarily',
        body: 'Use something and return it later.',
      ),
      CardBackSection(
        title: 'Example & collocation',
        heading: 'borrow a book',
        body: 'May I borrow this book?',
      ),
    ],
  );

  testWidgets('labels generated content as a draft and requires save', (
    tester,
  ) async {
    List<WordCardDraft>? saved;
    await tester.pumpWidget(
      app(
        WordDraftReviewScreen(
          initialDeckTitle: 'Captured words',
          loadDrafts: () async => const [draft],
          onSave: (_, drafts) async => saved = drafts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('审核 AI 草稿'), findsOneWidget);
    expect(find.text('AI 草稿 · 需要确认'), findsOneWidget);
    expect(find.text('borrow'), findsOneWidget);
    expect(saved, isNull);

    await tester.tap(find.byKey(const ValueKey('save-generated-cards')));
    await tester.pumpAndSettle();
    expect(saved?.single.prompt, 'borrow');
  });

  testWidgets('keeps selected words safe when generation fails', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        WordDraftReviewScreen(
          initialDeckTitle: 'Captured words',
          loadDrafts: () async {
            calls += 1;
            throw StateError('offline');
          },
          onSave: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂时无法生成卡片'), findsOneWidget);
    expect(find.text('已保留你的单词选择，可以重新生成草稿。'), findsOneWidget);
    await tester.tap(find.text('重新生成'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
