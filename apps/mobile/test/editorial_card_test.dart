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
    expect(find.byKey(const ValueKey('word-classification')), findsOneWidget);
    expect(find.byKey(const ValueKey('lexical-rule')), findsOneWidget);
    expect(find.text('borrow'), findsOneWidget);
    expect(find.bySemanticsLabel('卡片正面：borrow'), findsOneWidget);
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
    expect(find.bySemanticsLabel('卡片背面：速度 = 路程 ÷ 时间'), findsOneWidget);
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
