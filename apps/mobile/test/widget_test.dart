import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/auth/auth_service.dart';
import 'package:loopcard/widgets/brand_lockup.dart';
import 'package:loopcard/data/deck_repository.dart';
import 'package:loopcard/main.dart';
import 'package:loopcard/ocr/word_capture_flow.dart';

void main() {
  testWidgets('switches between all three primary pages', (tester) async {
    await tester.pumpWidget(const LoopCardApp());
    final navigation = find.byKey(const ValueKey('primary-navigation-dock'));
    final initialNavigationRect = tester.getRect(navigation);
    final brandRect = tester.getRect(find.byType(BrandLockup));

    await tester.tap(find.byKey(const ValueKey('primary-nav-decks')));
    await tester.pumpAndSettle();
    expect(tester.getRect(navigation), initialNavigationRect);
    expect(tester.getRect(find.byType(BrandLockup)), brandRect);
    expect(find.text('全部卡包'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-market')), findsOneWidget);
    expect(find.text('日常英语词汇'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('primary-nav-profile')));
    await tester.pumpAndSettle();
    expect(tester.getRect(navigation), initialNavigationRect);
    expect(tester.getRect(find.byType(BrandLockup)), brandRect);
    expect(find.text('user'), findsOneWidget);
    expect(find.text('连续天数'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('primary-nav-learn')));
    await tester.pumpAndSettle();
    expect(tester.getRect(navigation), initialNavigationRect);
    expect(tester.getRect(find.byType(BrandLockup)), brandRect);
    expect(find.text('拍照生成卡片'), findsOneWidget);
  });

  test('adding the same market deck is idempotent', () async {
    final repository = MemoryDeckRepository();
    expect(
      await repository.addMarketDeck('everyday-english-core'),
      MarketAddResult.added,
    );
    expect(
      await repository.addMarketDeck('everyday-english-core'),
      MarketAddResult.alreadyAdded,
    );
  });

  testWidgets('signs in with email from the signed-out state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = MemoryAuthService();
    await tester.pumpWidget(LoopCardApp(authService: auth));

    expect(find.text('欢迎回来'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('main')), findsOneWidget);
    expect(auth.currentUser?.email, 'reader@example.com');
  });

  testWidgets(
    'keeps the login brand stable and form reachable above the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);

      await tester.pumpWidget(LoopCardApp(authService: MemoryAuthService()));
      final emailField = find.byKey(const ValueKey('login-email'));
      final initialBrand = tester.getRect(find.byType(BrandLockup));

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.tap(emailField);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(BrandLockup)), initialBrand);
      expect(
        tester.getSize(find.byKey(const ValueKey('design-canvas-content'))),
        const Size(390, 524),
      );
      final submit = find.byKey(const ValueKey('login-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(submit).dy, lessThanOrEqualTo(524));
      expect(tester.getRect(find.byType(BrandLockup)), initialBrand);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opens a deck and advances after rating a card', (tester) async {
    await tester.pumpWidget(const LoopCardApp());

    expect(find.text('日常英语词汇'), findsOneWidget);
    expect(find.text('常见化学式'), findsOneWidget);

    await tester.tap(find.text('日常英语词汇'));
    await tester.pumpAndSettle();
    expect(find.text('本轮练习'), findsOneWidget);
    expect(find.text('复习 20 张到期卡'), findsWidgets);
    expect(find.text('熟悉'), findsOneWidget);
    expect(find.text('记不牢'), findsOneWidget);
    expect(find.text('不熟悉'), findsOneWidget);
    expect(find.text('复习 20 张到期卡'), findsWidgets);

    await tester.tap(find.text('复习 20 张到期卡').last);
    await tester.pumpAndSettle();
    expect(find.text('borrow'), findsOneWidget);

    await tester.tap(find.text('borrow'));
    await tester.pumpAndSettle();
    expect(find.text('v.'), findsOneWidget);
    expect(find.text('借入；借用'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rate-up')));
    await tester.pumpAndSettle();
    expect(find.text('lend'), findsOneWidget);
  });

  testWidgets('shows loading while a camera image is being recognized', (
    tester,
  ) async {
    final completer = Completer<List<String>?>();
    await tester.pumpWidget(
      LoopCardApp(
        wordCaptureFlow: _FakeWordCaptureFlow(() => completer.future),
      ),
    );

    await tester.tap(find.text('拍照生成卡片'));
    await tester.pump();

    expect(find.text('正在识别…'), findsOneWidget);

    completer.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('拍照生成卡片'), findsOneWidget);
  });

  testWidgets('opens a selectable result after successful OCR', (tester) async {
    await tester.pumpWidget(
      LoopCardApp(
        wordCaptureFlow: _FakeWordCaptureFlow(() async => ['borrow', 'lend']),
      ),
    );

    await tester.tap(find.text('拍照生成卡片'));
    await tester.pumpAndSettle();

    expect(find.text('识别结果'), findsOneWidget);
    expect(find.text('borrow'), findsOneWidget);
    expect(find.text('lend'), findsOneWidget);
  });

  testWidgets('reports empty OCR results', (tester) async {
    await tester.pumpWidget(
      LoopCardApp(wordCaptureFlow: _FakeWordCaptureFlow(() async => [])),
    );

    await tester.tap(find.text('拍照生成卡片'));
    await tester.pumpAndSettle();

    expect(find.text('没有识别到英文单词，请重新拍摄'), findsOneWidget);
  });

  testWidgets('shows sanitized OCR errors', (tester) async {
    await tester.pumpWidget(
      LoopCardApp(
        wordCaptureFlow: _FakeWordCaptureFlow(
          () async => throw const OcrException('文字识别失败（错误码 17）'),
        ),
      ),
    );

    await tester.tap(find.text('拍照生成卡片'));
    await tester.pumpAndSettle();

    expect(find.text('识别失败，请稍后重试'), findsOneWidget);
  });
}

class _FakeWordCaptureFlow implements WordCaptureFlow {
  const _FakeWordCaptureFlow(this.callback);

  final Future<List<String>?> Function() callback;

  @override
  Future<List<String>?> captureWords() => callback();
}
