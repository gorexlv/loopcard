import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/models/card_models.dart';
import 'package:loopcard/screens/result_screen.dart';
import 'package:loopcard/screens/study_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  const cards = [
    StudyCard(
      id: 'a',
      prompt: 'borrow',
      sections: [CardBackSection(title: 'Meaning', heading: '借入', body: '')],
    ),
    StudyCard(
      id: 'b',
      prompt: 'lend',
      sections: [
        CardBackSection(title: 'Meaning', heading: '借出', body: ''),
        CardBackSection(title: 'Example', heading: 'lend a hand', body: '帮助某人'),
      ],
    ),
    StudyCard(
      id: 'c',
      prompt: 'context',
      sections: [CardBackSection(title: 'Meaning', heading: '语境', body: '')],
    ),
  ];
  const deck = CardDeck(
    id: 'result-test',
    title: '结果测试卡包',
    subtitle: '',
    kind: CardKind.word,
    cards: cards,
    mastered: 0,
    fuzzy: 0,
    forgotten: 0,
  );
  const attempts = [
    CardAttempt(
      cardId: 'a',
      prompt: 'borrow',
      familiarity: Familiarity.mastered,
    ),
    CardAttempt(cardId: 'b', prompt: 'lend', familiarity: Familiarity.fuzzy),
    CardAttempt(
      cardId: 'c',
      prompt: 'context',
      familiarity: Familiarity.forgotten,
    ),
  ];

  Widget app({
    TextScaler textScaler = TextScaler.noScaling,
    Future<List<CardScheduleUpdate>> Function()? saveAttempts,
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
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: ResultScreen(
      deck: deck,
      attempts: attempts,
      saveAttempts: saveAttempts,
    ),
  );

  testWidgets('shows the result distribution and per-card schedule', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (final key in [
      'result-mastered-count',
      'result-fuzzy-count',
      'result-forgotten-count',
      'result-distribution',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.text('3 天后'), findsOneWidget);
    expect(find.text('1 天后'), findsOneWidget);
    expect(find.text('10 分钟后'), findsOneWidget);
    expect(find.byKey(const ValueKey('result-card-list')), findsOneWidget);
  });

  testWidgets('shows a retry action when background persistence fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    final retry = Completer<List<CardScheduleUpdate>>();
    await tester.pumpWidget(
      app(
        saveAttempts: () {
          calls += 1;
          if (calls == 1) return Future.error(StateError('offline'));
          return retry.future;
        },
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('result-sync-failed')), findsOneWidget);
    expect(find.text('重新保存'), findsOneWidget);

    await tester.tap(find.text('重新保存'));
    await tester.pump();
    expect(calls, 2);
    expect(find.byKey(const ValueKey('result-syncing')), findsOneWidget);

    retry.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('result-sync-failed')), findsNothing);
  });

  testWidgets('opens only cards from the selected result status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('result-fuzzy-count')));
    await tester.pumpAndSettle();

    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('lend'), findsOneWidget);
    expect(find.text('borrow'), findsNothing);
    expect(find.text('context'), findsNothing);
  });

  testWidgets('result-card review interactions never change familiarity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('result-fuzzy-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditorialCard));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(EditorialCard), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(find.text('lend a hand'), findsOneWidget);

    await tester.drag(find.byType(EditorialCard), const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('borrow'), findsOneWidget);
    expect(find.text('lend'), findsOneWidget);
    expect(find.text('context'), findsOneWidget);
    expect(find.byKey(const ValueKey('show-study-results')), findsNothing);
  });

  testWidgets('stays usable on a compact screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(textScaler: const TextScaler.linear(1.3)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('finish-results'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('本轮练习完成'), findsOneWidget);
  });
}
