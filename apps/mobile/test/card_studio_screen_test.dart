import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/card_visuals.dart';
import 'package:loopcard/cards/editorial_card.dart';
import 'package:loopcard/data/demo_data.dart';
import 'package:loopcard/screens/card_studio_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

void main() {
  testWidgets(
    'studio constrains theme, density, background, and face controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: LoopTheme.dark,
          home: CardStudioScreen(
            card: DemoData.wordDeck.cards.first,
            kind: DemoData.wordDeck.kind,
          ),
        ),
      );
      await tester.pumpAndSettle();

      EditorialCard preview() => tester.widget(find.byType(EditorialCard));
      expect(
        tester.getSize(find.byType(EditorialCard)).aspectRatio,
        closeTo(354 / 500, 0.01),
      );
      expect(preview().preferences.theme, CardThemeFamily.paper);

      await tester.tap(find.text('宇宙'));
      await tester.pumpAndSettle();
      expect(preview().preferences.theme, CardThemeFamily.cosmos);

      await tester.ensureVisible(find.text('紧凑'));
      await tester.tap(find.text('紧凑'));
      await tester.pumpAndSettle();
      expect(preview().preferences.density, CardDensity.compact);

      await tester.ensureVisible(find.text('AI 生成'));
      await tester.tap(find.text('AI 生成'));
      await tester.pumpAndSettle();
      expect(find.textContaining('已回退官方主题'), findsOneWidget);

      await tester.ensureVisible(find.text('查看背面'));
      await tester.tap(find.text('查看背面'));
      await tester.pumpAndSettle();
      expect(preview().face, CardFace.back);
      expect(tester.takeException(), isNull);
    },
  );
}
