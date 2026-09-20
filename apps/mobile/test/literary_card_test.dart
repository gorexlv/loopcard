import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/generated_card_face.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/theme/loop_theme.dart';

const poem = StudyCard(
  id: 'poem',
  prompt: '静夜思',
  presentation: {
    'skill': 'poetry',
    'layout': 'centered',
    'literary': {'title': '静夜思', 'author': '李白', 'dynasty': '唐'},
  },
  sections: [
    CardBackSection(
      title: '原文',
      heading: '',
      body: '床前明月光，<br>疑是地上霜。<br/>举头望明月，<BR />低头思故乡。',
    ),
    CardBackSection(title: '释义', heading: '', body: '明月引起对故乡的思念。'),
    CardBackSection(title: '字词注释', heading: '', body: '举：抬起。'),
  ],
);
Widget app(StudyCard card, {bool back = false}) => MaterialApp(
  theme: LoopTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 340,
        height: 340,
        child: GeneratedCardFace(card: card, back: back),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'title author and dynasty occupy separate rows without face labels',
    (tester) async {
      await tester.pumpWidget(app(poem));
      expect(find.text('正面'), findsNothing);
      expect(
        tester.getTopLeft(find.text('李白')).dy,
        greaterThan(tester.getBottomLeft(find.text('静夜思')).dy),
      );
      expect(
        tester.getTopLeft(find.text('唐')).dy,
        greaterThan(tester.getBottomLeft(find.text('李白')).dy),
      );
    },
  );
  testWidgets('swipe pages, navigate back, and reset when card changes', (
    tester,
  ) async {
    await tester.pumpWidget(app(poem, back: true));
    expect(find.text('背面'), findsNothing);
    for (final line in ['床前明月光，', '疑是地上霜。', '举头望明月，', '低头思故乡。']) {
      expect(find.text(line), findsOneWidget);
    }
    expect(find.textContaining('<br'), findsNothing);
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('literary-back-pages')),
      const Offset(-280, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('明月引起对故乡的思念。').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('下一页'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('上一页'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.pumpWidget(
      app(
        StudyCard(
          id: 'other',
          prompt: '另一首',
          presentation: {'skill': 'poetry'},
          sections: poem.sections,
        ),
        back: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('long classical page scrolls vertically without changing page', (
    tester,
  ) async {
    final card = StudyCard(
      id: 'long',
      prompt: '古文',
      presentation: const {'skill': 'classical'},
      sections: [
        CardBackSection(
          title: '原文',
          heading: '',
          body: '${List.filled(35, '原文段落。').join('\n')}\n结尾标记',
        ),
        const CardBackSection(title: '释义', heading: '', body: '译文'),
      ],
    );
    await tester.pumpWidget(app(card, back: true));
    final scroll = find.byKey(const PageStorageKey('literary-page-0'));
    await tester.drag(scroll, const Offset(0, -2200));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    final vertical = tester.state<ScrollableState>(
      find.descendant(of: scroll, matching: find.byType(Scrollable)),
    );
    expect(vertical.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
