import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/models/card_models.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 354, height: 500, child: child)),
    ),
  );

  const word = StudyCard(
    id: 'borrow',
    prompt: 'borrow',
    eyebrow: 'LANGUAGE / 01',
    supportingText: '/ˈbɒrəʊ/ · verb',
    hint: 'Starts with b · 6 letters',
    wordContent: WordCardContent(
      partOfSpeech: 'v.',
      pronunciations: [WordPronunciation(region: 'UK', ipa: '/ˈbɒrəʊ/')],
      definition: '借入；借用',
      example: WordExample(
        sentence: 'May I borrow this book?',
        translation: '我可以借这本书吗？',
      ),
    ),
    sections: [
      CardBackSection(
        title: '核心释义',
        heading: '借入；借用',
        body: '从别人或某处暂时取得并使用，之后需要归还。',
      ),
    ],
  );

  const formula = StudyCard(
    id: 'water',
    prompt: 'H₂O',
    eyebrow: 'CHEMISTRY / 01',
    supportingText: 'WATER · 18.015',
    sections: [
      CardBackSection(
        title: '变量图例',
        heading: '2H · 1O',
        body: '两个氢原子与一个氧原子构成一个水分子。',
      ),
    ],
  );

  const problem = StudyCard(
    id: 'distance',
    prompt: '一辆车 2 小时行驶 120 千米，它的平均速度是多少？',
    eyebrow: 'MATH / REASONING',
    supportingText: '条件 02 · 求平均速度',
    sections: [
      CardBackSection(
        title: '关键突破',
        heading: '速度 = 路程 ÷ 时间',
        body: '识别路程与时间\n代入 120 ÷ 2\n得到 60 千米/时',
      ),
    ],
  );

  testWidgets('renders distinct word front composition', (tester) async {
    await tester.pumpWidget(
      app(const EditorialCard(card: word, kind: CardKind.word)),
    );

    expect(find.byKey(const ValueKey('word-composition')), findsOneWidget);
    expect(find.byKey(const ValueKey('word-classification')), findsNothing);
    expect(find.byKey(const ValueKey('word-prompt-fit')), findsOneWidget);
    expect(find.byKey(const ValueKey('word-cue-mask')), findsOneWidget);
    expect(find.byKey(const ValueKey('revealed-word-cue')), findsNothing);
    expect(find.text('v.   UK /ˈbɒrəʊ/'), findsNothing);
    expect(find.byKey(const ValueKey('lexical-rule')), findsNothing);
    expect(find.text('LANGUAGE / 01'), findsNothing);
    expect(find.text('/ˈbɒrəʊ/ · verb'), findsNothing);
    expect(find.text('Reveal hint'), findsOneWidget);
    expect(find.text('Starts with b · 6 letters'), findsNothing);
    expect(find.text('borrow'), findsOneWidget);
    expect(find.bySemanticsLabel('Card front: borrow'), findsOneWidget);
    final fit = tester.widget<FittedBox>(
      find.byKey(const ValueKey('word-prompt-fit')),
    );
    final prompt = tester.widget<Text>(find.text('borrow'));
    expect(fit.alignment, Alignment.center);
    expect(prompt.style?.fontFamily, 'Inter');
    expect(prompt.style?.fontWeight, FontWeight.w600);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('word-cue-mask'))).dy,
      greaterThan(tester.getBottomLeft(find.text('borrow')).dy),
    );
  });

  testWidgets('reveals part of speech and IPA in place', (tester) async {
    var revealed = false;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => EditorialCard(
            card: word,
            kind: CardKind.word,
            hintRevealed: revealed,
            onHintTap: () => setState(() => revealed = true),
          ),
        ),
      ),
    );

    final maskedRect = tester.getRect(
      find.byKey(const ValueKey('word-cue-surface')),
    );
    await tester.tap(find.byKey(const ValueKey('card-hint-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('word-cue-mask')), findsNothing);
    expect(find.byKey(const ValueKey('revealed-word-cue')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('word-cue-surface'))),
      maskedRect,
    );
  });

  testWidgets('keeps a long word on one line and scales it to the card', (
    tester,
  ) async {
    const longWord = StudyCard(
      id: 'characteristically',
      prompt: 'characteristically',
      sections: [
        CardBackSection(title: 'Meaning', heading: '典型地', body: '以某人或某物典型的方式。'),
      ],
      wordContent: WordCardContent(
        partOfSpeech: 'adv.',
        definition: '典型地',
        example: WordExample(
          sentence: 'She was characteristically calm.',
          translation: '她一如既往地冷静。',
        ),
      ),
    );

    await tester.pumpWidget(
      app(const EditorialCard(card: longWord, kind: CardKind.word)),
    );

    final prompt = tester.widget<Text>(find.text('characteristically'));
    expect(prompt.maxLines, 1);
    expect(prompt.style?.fontFamily, 'Inter');
    expect(find.byKey(const ValueKey('word-prompt-fit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders distinct formula front composition', (tester) async {
    await tester.pumpWidget(
      app(const EditorialCard(card: formula, kind: CardKind.formula)),
    );

    expect(find.byKey(const ValueKey('formula-composition')), findsOneWidget);
    expect(find.byKey(const ValueKey('formula-atom-system')), findsOneWidget);
    expect(find.text('H₂O'), findsOneWidget);
  });

  testWidgets('renders distinct problem front composition', (tester) async {
    await tester.pumpWidget(
      app(const EditorialCard(card: problem, kind: CardKind.problem)),
    );

    expect(find.byKey(const ValueKey('problem-composition')), findsOneWidget);
    expect(find.byKey(const ValueKey('condition-markers')), findsOneWidget);
    expect(find.textContaining('120 千米'), findsOneWidget);
  });

  testWidgets('back puts the selected answer before supporting body', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const EditorialCard(
          card: problem,
          kind: CardKind.problem,
          face: CardFace.back,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('answer-heading')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-body')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-step-0')), findsOneWidget);
    expect(find.bySemanticsLabel('Card back: 速度 = 路程 ÷ 时间'), findsOneWidget);
    expect(find.bySemanticsLabel('关键突破'), findsOneWidget);
    expect(find.bySemanticsLabel('Answer detail'), findsOneWidget);
  });

  testWidgets('back exposes readable content and 48dp paging controls', (
    tester,
  ) async {
    const pagedWord = StudyCard(
      id: 'paged-word',
      prompt: 'borrow',
      sections: [
        CardBackSection(
          title: 'Meaning',
          heading: '借入；借用',
          body: '暂时取得并在之后归还。',
        ),
        CardBackSection(
          title: 'Example & collocation',
          heading: 'borrow a book',
          body: 'May I borrow this book?',
        ),
      ],
    );
    await tester.pumpWidget(
      app(
        EditorialCard(
          card: pagedWord,
          kind: CardKind.word,
          face: CardFace.back,
          onTap: () {},
          onSectionChanged: (_) {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Card back: 借入；借用'), findsOneWidget);
    expect(find.bySemanticsLabel('暂时取得并在之后归还。'), findsOneWidget);
    expect(find.bySemanticsLabel('Explanation 1 / 2'), findsOneWidget);
    expect(find.byTooltip('Previous explanation'), findsOneWidget);
    expect(find.byTooltip('Next explanation'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('previous-back-section'))),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('next-back-section'))),
      const Size(48, 48),
    );
  });

  testWidgets('structured word back keeps lexical metadata in its header', (
    tester,
  ) async {
    var pronunciationPlayed = false;
    const structuredWord = StudyCard(
      id: 'structured-word',
      prompt: 'borrow',
      sections: [
        CardBackSection(
          title: 'Meaning',
          heading: '借入；借用',
          body: '暂时取得并在之后归还。',
        ),
      ],
      wordContent: WordCardContent(
        partOfSpeech: 'v.',
        pronunciations: [WordPronunciation(region: 'UK', ipa: '/ˈbɒrəʊ/')],
        definition: '借入；借用',
        englishDefinition: 'to take something temporarily and return it',
        usagePatterns: ['borrow something from someone'],
        example: WordExample(
          sentence: 'May I borrow your charger?',
          translation: '我可以借用你的充电器吗？',
        ),
        collocations: ['borrow money', 'borrow a book'],
      ),
    );

    await tester.pumpWidget(
      app(
        EditorialCard(
          card: structuredWord,
          kind: CardKind.word,
          face: CardFace.back,
          onPronounce: () => pronunciationPlayed = true,
          onSectionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('borrow'), findsOneWidget);
    expect(find.text('v.'), findsOneWidget);
    expect(find.text('UK /ˈbɒrəʊ/'), findsOneWidget);
    expect(find.text('borrow something from someone'), findsOneWidget);
    expect(find.bySemanticsLabel('Explanation 1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('play-word-pronunciation')));
    expect(pronunciationPlayed, isTrue);
  });

  testWidgets('long back content scrolls without overflow', (tester) async {
    final longCard = StudyCard(
      id: 'long',
      prompt: '长题目',
      sections: [
        CardBackSection(
          title: '解法',
          heading: '关键结论',
          body: List.filled(30, '这是一个需要保留清晰层级的详细解题步骤。').join('\n'),
        ),
      ],
    );

    await tester.pumpWidget(
      app(
        EditorialCard(
          card: longCard,
          kind: CardKind.problem,
          face: CardFace.back,
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'equations that start with a number are not parsed as step numbers',
    (tester) async {
      const equationCard = StudyCard(
        id: 'equation',
        prompt: '平均速度',
        sections: [
          CardBackSection(
            title: '关键突破',
            heading: '代入关系式',
            body: '120 ÷ 2 = 60',
          ),
        ],
      );

      await tester.pumpWidget(
        app(
          const EditorialCard(
            card: equationCard,
            kind: CardKind.problem,
            face: CardFace.back,
          ),
        ),
      );

      expect(find.text('120 ÷ 2 = 60'), findsOneWidget);
      expect(find.text('120'), findsNothing);
    },
  );
}
