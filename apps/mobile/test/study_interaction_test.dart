import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  const first = StudyCard(
    id: 'first',
    prompt: 'borrow',
    hint: 'Starts with b · 6 letters',
    sections: [
      CardBackSection(title: 'Meaning', heading: '借入；借用', body: '暂时取得并在之后归还。'),
      CardBackSection(
        title: 'Example & collocation',
        heading: 'borrow a book',
        body: 'May I borrow this book?',
      ),
    ],
  );
  const second = StudyCard(
    id: 'second',
    prompt: 'lend',
    sections: [
      CardBackSection(title: 'Meaning', heading: '借给；借出', body: '让别人暂时使用。'),
    ],
  );

  Widget app(
    List<StudyCard> cards, {
    Future<List<CardScheduleUpdate>> Function(List<CardAttempt>)? onCompleted,
    TextScaler? textScaler,
  }) => MaterialApp(
    locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: LoopTheme.dark,
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: StudyScreen(
      deck: CardDeck(
        id: 'test',
        title: '测试卡包',
        subtitle: '',
        kind: CardKind.word,
        cards: cards,
        mastered: 0,
        fuzzy: 0,
        forgotten: 0,
      ),
      onAttemptsCompleted: onCompleted,
    ),
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('focused study header omits the deck title', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('测试卡包'), findsNothing);
  });

  testWidgets('unassisted up swipe is familiar and down swipe is unfamiliar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    List<CardAttempt>? saved;
    await tester.pumpWidget(
      app(
        const [first, second],
        onCompleted: (attempts) async {
          saved = attempts;
          return const [];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(EditorialCard)).height,
      moreOrLessEquals(616, epsilon: 0.1),
    );

    await tester.drag(find.byType(EditorialCard), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.text('lend'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('已记录本张卡片'), findsNothing);

    await tester.drag(find.byType(EditorialCard), const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('show-study-results')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-study-results')));
    await tester.pumpAndSettle();

    expect(saved, hasLength(2));
    expect(saved![0].familiarity, Familiarity.mastered);
    expect(saved![0].assistanceUsed, isFalse);
    expect(saved![1].familiarity, Familiarity.forgotten);
  });

  testWidgets('shows results without waiting for attempt persistence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final persistence = Completer<List<CardScheduleUpdate>>();
    await tester.pumpWidget(
      app(const [first], onCompleted: (_) => persistence.future),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('show-study-results')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('result-card-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-syncing')), findsOneWidget);
    expect(persistence.isCompleted, isFalse);

    persistence.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('automatically shows results after a short undo window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('show-study-results')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('result-card-list')), findsOneWidget);
  });

  testWidgets('revealing a hint makes the upward result fuzzy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    List<CardAttempt>? saved;
    await tester.pumpWidget(
      app(
        const [first],
        onCompleted: (attempts) async {
          saved = attempts;
          return const [];
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('word-classification')), findsNothing);
    expect(find.byKey(const ValueKey('word-cue-mask')), findsOneWidget);
    expect(find.text('查看提示'), findsOneWidget);
    expect(find.text('Starts with b · 6 letters'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('card-hint-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('word-cue-mask')), findsNothing);
    expect(find.text('Starts with b · 6 letters'), findsOneWidget);
    expect(find.text('记不牢'), findsOneWidget);
    expect(find.text('借入；借用'), findsNothing);

    await tester.drag(find.byType(EditorialCard), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('show-study-results')));
    await tester.pumpAndSettle();

    expect(saved!.single.familiarity, Familiarity.fuzzy);
    expect(saved!.single.assistanceUsed, isTrue);
  });

  testWidgets('card back keeps its header and pages content horizontally', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(find.text('借入；借用'), findsOneWidget);
    expect(find.text('暂时取得并在之后归还。'), findsOneWidget);
    expect(find.text('点按返回正面 · 左右滑动切换解释'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('back-content')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('借入；借用'), findsNothing);
    expect(find.text('borrow'), findsOneWidget);
    expect(find.text('borrow a book'), findsOneWidget);
    expect(find.byKey(const ValueKey('show-study-results')), findsNothing);
  });

  testWidgets('explanation transition never paints two sections together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('back-section-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-back-section')));
    await tester.pump();
    expect(find.byKey(const ValueKey('back-section-0')), findsNothing);
    expect(find.byKey(const ValueKey('back-section-1')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 110));
    expect(find.byKey(const ValueKey('back-section-0')), findsNothing);
    expect(find.byKey(const ValueKey('back-section-1')), findsOneWidget);
  });

  testWidgets('a diagonal explanation swipe never rates or moves the card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    final cardTopBeforeSwipe = tester.getTopLeft(find.byType(EditorialCard)).dy;
    await tester.drag(
      find.byKey(const ValueKey('back-content')),
      const Offset(-220, -70),
    );
    await tester.pumpAndSettle();

    expect(find.text('borrow a book'), findsOneWidget);
    expect(find.byKey(const ValueKey('show-study-results')), findsNothing);
    expect(
      tester.getTopLeft(find.byType(EditorialCard)).dy,
      moreOrLessEquals(cardTopBeforeSwipe),
    );
  });

  testWidgets('tapping the back returns to the assisted card front', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    List<CardAttempt>? saved;
    await tester.pumpWidget(
      app(
        const [first],
        onCompleted: (attempts) async {
          saved = attempts;
          return const [];
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(find.text('借入；借用'), findsOneWidget);
    expect(find.bySemanticsLabel('卡片背面：借入；借用'), findsOneWidget);
    expect(find.bySemanticsLabel('解释 1 / 2'), findsOneWidget);

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('word-composition')), findsOneWidget);
    expect(find.text('借入；借用'), findsNothing);
    expect(find.text('记不牢'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('show-study-results')));
    await tester.pumpAndSettle();
    expect(saved!.single.familiarity, Familiarity.fuzzy);
    expect(saved!.single.assistanceUsed, isTrue);
  });

  testWidgets('the last rating can be undone before persistence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('undo-final-rating')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('undo-final-rating')));
    await tester.pumpAndSettle();
    expect(find.text('borrow'), findsOneWidget);
    expect(find.byKey(const ValueKey('show-study-results')), findsNothing);
  });

  testWidgets('a rating can be undone from the next card header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first, second]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    expect(find.text('lend'), findsOneWidget);
    expect(find.byKey(const ValueKey('undo-last-rating')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('undo-last-rating')));
    await tester.pumpAndSettle();
    expect(find.text('borrow'), findsOneWidget);
    expect(find.byKey(const ValueKey('undo-last-rating')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('scrollable back content owns vertical gestures', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final longCard = StudyCard(
      id: 'long',
      prompt: 'context',
      sections: [
        CardBackSection(
          title: 'Meaning',
          heading: '语境；上下文',
          body: List.filled(18, '理解一段信息时，需要结合前后内容、使用场景以及说话者意图。').join('\n\n'),
        ),
      ],
    );
    await tester.pumpWidget(app([longCard, second]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(find.text('上下滚动查看全文 · 请点按下方完成评价'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('back-section-0')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    expect(find.text('语境；上下文'), findsOneWidget);
    expect(find.text('lend'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    expect(find.text('lend'), findsOneWidget);
  });

  testWidgets('short back content still supports a vertical rating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(find.text('上下滚动查看全文 · 请点按下方完成评价'), findsNothing);
    await tester.drag(find.byType(EditorialCard), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('show-study-results')), findsOneWidget);
  });

  testWidgets('study layout remains usable on a compact large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(const [first, second], textScaler: const TextScaler.linear(1.3)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final cardRect = tester.getRect(find.byType(EditorialCard));
    expect(cardRect.left, greaterThanOrEqualTo(0));
    expect(cardRect.right, lessThanOrEqualTo(320));
    expect(cardRect.bottom, lessThan(580));
    expect(
      tester.getSize(find.byKey(const ValueKey('rate-up'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('flipping the card keeps its height stable', (tester) async {
    tester.view.physicalSize = const Size(451, 884);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    final frontHeight = tester.getSize(find.byType(EditorialCard)).height;
    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    final backHeight = tester.getSize(find.byType(EditorialCard)).height;

    expect(backHeight, moreOrLessEquals(frontHeight));
    expect(find.text('点按返回正面 · 左右滑动切换解释'), findsNothing);

    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(EditorialCard)).height,
      moreOrLessEquals(frontHeight),
    );
  });

  testWidgets('rating reveals the next card behind the active card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first, second]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('next-study-card-preview')),
      findsOneWidget,
    );
    final initialOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('next-study-card-opacity')),
    );
    expect(initialOpacity.opacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 120));
    final advancingOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('next-study-card-opacity')),
    );
    expect(advancingOpacity.opacity, greaterThan(initialOpacity.opacity));
  });

  testWidgets('face change uses a perspective flip transition', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final transforms = tester
        .widgetList<Transform>(find.byKey(const ValueKey('card-face-flip')))
        .toList();
    expect(transforms, isNotEmpty);
    expect(
      transforms.any((widget) => widget.transform.storage[11] != 0),
      isTrue,
    );
    expect(
      transforms.any((widget) => widget.transform.storage[0].abs() < 0.99),
      isTrue,
    );
  });

  testWidgets(
    'back content follows a horizontal drag without vertical wobble',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const [first]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(EditorialCard));
      await tester.pumpAndSettle();
      final cardTop = tester.getTopLeft(find.byType(EditorialCard)).dy;
      final content = find.byKey(const ValueKey('back-content'));
      final gesture = await tester.startGesture(tester.getCenter(content));
      await gesture.moveBy(const Offset(-40, -8));
      await tester.pump();

      final motion = tester.widget<Transform>(
        find.byKey(const ValueKey('back-content-motion')),
      );
      expect(motion.transform.storage[12], lessThan(0));
      expect(motion.transform.storage[13], 0);
      expect(
        tester.getTopLeft(find.byType(EditorialCard)).dy,
        moreOrLessEquals(cardTop),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('borrow a book'), findsNothing);
    },
  );

  testWidgets('pressing the card gives immediate material feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first]));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(EditorialCard)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final pressMotion = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('editorial-card-press-motion')),
    );
    expect(pressMotion.scale, lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('pressing a rating action compresses before card exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first, second]));
    await tester.pumpAndSettle();

    final rateUp = find.byKey(const ValueKey('rate-up'));
    final gesture = await tester.startGesture(tester.getCenter(rateUp));
    await tester.pump(const Duration(milliseconds: 100));

    final pressMotion = tester.widget<AnimatedScale>(
      find.descendant(of: rateUp, matching: find.byType(AnimatedScale)),
    );
    expect(pressMotion.scale, lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('lend'), findsOneWidget);
  });

  testWidgets('a face transition cannot be mistaken for a rating gesture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const [first, second]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditorialCard));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('card-back')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    expect(find.text('借入；借用'), findsOneWidget);
    expect(find.text('lend'), findsNothing);
  });
}
