import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/main.dart';
import 'package:loopcard/onboarding/onboarding_store.dart';

void main() {
  testWidgets('completes the three-question onboarding and persists answers', (
    tester,
  ) async {
    final store = MemoryOnboardingStore();
    await tester.pumpWidget(
      LoopCardApp(onboardingStore: store, initialOnboardingCompleted: false),
    );

    expect(find.text('你想从哪种方式\n开始制作卡片？'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    expect(find.text('你更喜欢怎样\n安排记忆节奏？'), findsOneWidget);

    await tester.tap(find.text('集中处理'));
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 张'));
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(find.text('拍照生成 · 集中处理'), findsOneWidget);
    expect(find.text('每天 30 张'), findsOneWidget);
    await tester.tap(find.text('开始使用 LoopCard'));
    await tester.pumpAndSettle();

    expect(find.text('拍照生成卡片'), findsOneWidget);
    expect(store.completed, isTrue);
    expect(store.answers?.source, 'camera');
    expect(store.answers?.pace, 'focus');
    expect(store.answers?.dailyGoal, 30);
  });

  testWidgets('starts locally without requiring an account', (tester) async {
    await tester.pumpWidget(
      LoopCardApp(
        onboardingStore: MemoryOnboardingStore(),
        initialOnboardingCompleted: false,
      ),
    );

    for (var index = 0; index < 3; index += 1) {
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
    }
    expect(find.text('开始使用 LoopCard'), findsOneWidget);
    expect(find.text('无需账号 · 数据保存在本机'), findsOneWidget);
    expect(find.textContaining('微信'), findsNothing);
  });

  testWidgets('plays the splash before opening the completed app', (
    tester,
  ) async {
    await tester.pumpWidget(
      LoopCardApp(
        showSplash: true,
        onboardingStore: MemoryOnboardingStore(completed: true),
      ),
    );

    expect(find.text('让记忆，循环发生'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('拍照生成卡片'), findsOneWidget);
  });
}
