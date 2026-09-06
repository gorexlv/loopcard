import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/cards/card_visuals.dart';
import 'package:loopcard/models/card_models.dart';

void main() {
  group('CardVisualEngine', () {
    const engine = CardVisualEngine();

    test('recommends a distinct official theme for each knowledge kind', () {
      expect(engine.recommend(CardKind.word).theme, CardThemeFamily.paper);
      expect(engine.recommend(CardKind.formula).theme, CardThemeFamily.lab);
      expect(engine.recommend(CardKind.problem).theme, CardThemeFamily.mono);
    });

    test(
      'falls back to an official theme when a custom background is unsafe',
      () {
        const preferences = CardVisualPreferences(
          theme: CardThemeFamily.cosmos,
          backgroundSource: CardBackgroundSource.userImage,
        );

        final result = engine.resolve(
          kind: CardKind.formula,
          preferences: preferences,
          customBackgroundIsSafe: false,
        );

        expect(result.backgroundSource, CardBackgroundSource.official);
        expect(result.theme, CardThemeFamily.cosmos);
        expect(result.usedFallback, isTrue);
      },
    );

    test('uses compact density for long content', () {
      final result = engine.resolve(
        kind: CardKind.problem,
        preferences: const CardVisualPreferences(),
        contentLength: 260,
      );

      expect(result.density, CardDensity.compact);
      expect(result.displayScale, lessThan(1));
    });

    test('keeps short word prompts expressive', () {
      final result = engine.resolve(
        kind: CardKind.word,
        preferences: const CardVisualPreferences(),
        contentLength: 8,
      );

      expect(result.density, CardDensity.airy);
      expect(result.displayScale, greaterThan(1));
    });

    test('all official themes maintain high contrast foregrounds', () {
      for (final family in CardThemeFamily.values) {
        final tokens = CardThemeTokens.forFamily(family);
        expect(
          _contrastRatio(tokens.foreground, tokens.background),
          greaterThanOrEqualTo(4.5),
          reason: family.name,
        );
      }
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
