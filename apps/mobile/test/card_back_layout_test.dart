import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/cards/literary_layout.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import 'fixtures/card_back_samples.dart';

Widget app(
  StudyCard card, {
  double scale = 1,
  double width = 354,
  double height = 600,
}) => MaterialApp(
  theme: LoopTheme.light,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: EditorialCard(
            card: card,
            kind: card.presentation['skill'] == 'poetry'
                ? CardKind.problem
                : CardKind.word,
            face: CardFace.back,
          ),
        ),
      ),
    ),
  ),
);
void main() {
  testWidgets('word overview brings definition, example and pattern together', (
    tester,
  ) async {
    await tester.pumpWidget(app(DemoData.wordDeck.cards.first));
    await tester.pumpAndSettle();
    expect(find.text('借入；借用').hitTestable(), findsOneWidget);
    expect(
      find.text('Can I borrow your charger?').hitTestable(),
      findsOneWidget,
    );
    expect(
      find.text('borrow something from someone').hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('card-section-tab-0')), findsOneWidget);
  });
  testWidgets('generated structured words use the same overview', (
    tester,
  ) async {
    final word = DemoData.wordDeck.cards.first;
    await tester.pumpWidget(
      app(
        StudyCard(
          id: word.id,
          prompt: word.prompt,
          sections: word.sections,
          wordContent: word.wordContent,
          presentation: const {'skill': 'word', 'layout': 'centered'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(word.wordContent!.example.sentence).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('背面'), findsNothing);
  });
  testWidgets('long word and doubled text remain complete on a short card', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(longWordBack, scale: 2, width: 300, height: 420),
    );
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('characteristically'));
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
    expect(find.text('Scroll to read more'), findsNothing);
    expect(
      tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
      isTrue,
    );
    final content = find.byKey(const ValueKey('word-back-section-0'));
    await tester.drag(content, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('chat preview expands into a full reading surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LoopTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentCardCarousel(
              cards: [
                WordCardDraft(
                  prompt: stanzaPoem.prompt,
                  sections: stanzaPoem.sections,
                  presentation: stanzaPoem.presentation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('查看背面'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('展开阅读'));
    await tester.pumpAndSettle();
    expect(find.text('卡片预览'), findsOneWidget);
    expect(find.text('上阕').hitTestable(), findsOneWidget);
    await tester.tap(find.text('下阕'));
    await tester.pumpAndSettle();
    expect(find.text('无可奈何花落去，').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('custom back instructions do not leak excluded lexical fields', () {
    const card = StudyCard(
      id: 'custom',
      prompt: 'borrow',
      presentation: {'skill': 'word', 'back': '只显示例句，不要释义'},
      wordContent: WordCardContent(
        partOfSpeech: 'v.',
        definition: '借入',
        example: WordExample(
          sentence: 'May I borrow a pen?',
          translation: '能借支笔吗？',
        ),
      ),
      sections: [
        CardBackSection(
          title: '例句',
          heading: 'May I borrow a pen?',
          body: '能借支笔吗？',
        ),
      ],
    );
    expect(card.reviewWordContent, isNull);
    expect(card.learningSections, same(card.sections));
  });
  test('review grouping leaves persisted and editable sections unchanged', () {
    final word = DemoData.wordDeck.cards.first;
    expect(word.reviewSections.first.title, 'Word overview');
    expect(word.learningSections.first.title, 'Meaning');
    expect(
      word.learningSections[1].heading,
      word.wordContent!.example.sentence,
    );
    final draft = WordCardDraft(
      prompt: word.prompt,
      sections: word.sections,
      wordContent: word.wordContent,
    );
    expect(
      draft.learningSections[1].heading,
      word.wordContent!.example.sentence,
    );
  });
  test('line pairing preserves every original and every translation', () {
    final pages = literaryPages(alignedPoem);
    expect(pages, hasLength(2));
    expect(pages.first.lines, hasLength(4));
    expect(pages.first.translations, hasLength(4));
    expect(pages.first.lines.last, '低头思故乡。');
    expect(pages.first.translations.last, '低头思念故乡。');
    expect(pages.last.lines, hasLength(3));
  });
  testWidgets('ci has two tabs and keeps each translation with its stanza', (
    tester,
  ) async {
    await tester.pumpWidget(app(stanzaPoem));
    await tester.pumpAndSettle();
    expect(find.text('上阕'), findsOneWidget);
    expect(find.text('下阕'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    final original = find.byKey(const ValueKey('literary-line-0-0'));
    final translation = find.byKey(const ValueKey('literary-translation-0-0'));
    expect(
      tester.getTopLeft(translation).dy,
      greaterThan(tester.getBottomLeft(original).dy),
    );
    await tester.tap(find.text('下阕'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('无可奈何花落去，').hitTestable(), findsOneWidget);
    expect(find.text('花儿凋落，让人无可奈何，').hitTestable(), findsOneWidget);
    expect(find.text('上阕释义'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('mismatched translations remain complete and no stanza is guessed', () {
    final card = StudyCard(
      id: 'mismatch',
      prompt: '未分阕的作品',
      presentation: const {
        'skill': 'poetry',
        'literary': {'dynasty': '宋'},
      },
      sections: const [
        CardBackSection(title: '原文', heading: '', body: '甲句，乙句。丙句，丁句。'),
        CardBackSection(title: '释义', heading: '', body: '完整的解释。'),
      ],
    );
    final pages = literaryPages(card);
    expect(pages, hasLength(2));
    expect(pages.first.label, '原文');
    expect(pages.first.lines.join(), card.sections.first.body);
    expect(pages.first.translations, isEmpty);
    expect(pages.last.lines.single, '完整的解释。');
  });
  test(
    'legacy generated words preserve bilingual example without inventing data',
    () {
      const card = StudyCard(
        id: 'legacy-word',
        prompt: 'borrow',
        presentation: {'skill': 'word'},
        sections: [
          CardBackSection(title: '释义', heading: '借入', body: ''),
          CardBackSection(
            title: '例句',
            heading: '',
            body: 'I borrowed a book. 我借了一本书。',
          ),
        ],
      );
      expect(card.reviewWordContent!.example.sentence, 'I borrowed a book.');
      expect(card.reviewWordContent!.example.translation, '我借了一本书。');
      expect(card.reviewWordContent!.collocations, isEmpty);
    },
  );
}
