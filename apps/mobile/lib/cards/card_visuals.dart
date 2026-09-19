import 'package:flutter/material.dart';

import '../models/card_models.dart';
import '../theme/loop_theme.dart';

enum CardThemeFamily { aurora, paper, cosmos, lab, botanical, mono }

enum CardMood { quiet, editorial, vivid }

enum CardDensity { airy, balanced, compact }

enum CardBackgroundSource { official, userImage, generated }

@immutable
class CardVisualPreferences {
  const CardVisualPreferences({
    this.theme,
    this.mood = CardMood.editorial,
    this.density,
    this.backgroundSource = CardBackgroundSource.official,
    this.emphasizeAnswer = true,
  });

  final CardThemeFamily? theme;
  final CardMood mood;
  final CardDensity? density;
  final CardBackgroundSource backgroundSource;
  final bool emphasizeAnswer;

  CardVisualPreferences copyWith({
    CardThemeFamily? theme,
    CardMood? mood,
    CardDensity? density,
    CardBackgroundSource? backgroundSource,
    bool? emphasizeAnswer,
  }) {
    return CardVisualPreferences(
      theme: theme ?? this.theme,
      mood: mood ?? this.mood,
      density: density ?? this.density,
      backgroundSource: backgroundSource ?? this.backgroundSource,
      emphasizeAnswer: emphasizeAnswer ?? this.emphasizeAnswer,
    );
  }
}

@immutable
class ResolvedCardVisuals {
  const ResolvedCardVisuals({
    required this.theme,
    required this.mood,
    required this.density,
    required this.backgroundSource,
    required this.displayScale,
    this.usedFallback = false,
  });

  final CardThemeFamily theme;
  final CardMood mood;
  final CardDensity density;
  final CardBackgroundSource backgroundSource;
  final double displayScale;
  final bool usedFallback;
}

class CardVisualEngine {
  const CardVisualEngine();

  ResolvedCardVisuals recommend(CardKind kind) {
    return resolve(kind: kind, preferences: const CardVisualPreferences());
  }

  ResolvedCardVisuals resolve({
    required CardKind kind,
    required CardVisualPreferences preferences,
    int contentLength = 80,
    bool customBackgroundIsSafe = true,
  }) {
    final density = preferences.density ?? _densityFor(kind, contentLength);
    final requestedBackground = preferences.backgroundSource;
    final usesCustom = requestedBackground != CardBackgroundSource.official;
    final fallback = usesCustom && !customBackgroundIsSafe;
    return ResolvedCardVisuals(
      theme: CardThemeFamily.aurora,
      mood: preferences.mood,
      density: density,
      backgroundSource: fallback
          ? CardBackgroundSource.official
          : requestedBackground,
      displayScale: switch (density) {
        CardDensity.airy => 1.12,
        CardDensity.balanced => 1,
        CardDensity.compact => 0.88,
      },
      usedFallback: fallback,
    );
  }

  CardDensity _densityFor(CardKind kind, int length) {
    if (length > 220) return CardDensity.compact;
    if (kind == CardKind.word && length < 24) return CardDensity.airy;
    return CardDensity.balanced;
  }
}

@immutable
class CardThemeTokens {
  const CardThemeTokens({
    required this.background,
    required this.backgroundAlt,
    required this.foreground,
    required this.muted,
    required this.accent,
    required this.surface,
  });

  final Color background;
  final Color backgroundAlt;
  final Color foreground;
  final Color muted;
  final Color accent;
  final Color surface;

  static CardThemeTokens forContext(BuildContext context) =>
      fromPalette(context.loopColors);

  // Compatibility for older stored theme choices: all resolve to one material.
  static CardThemeTokens forFamily(CardThemeFamily family) =>
      fromPalette(LoopTheme.darkPalette);

  static CardThemeTokens fromPalette(LoopPalette palette) => CardThemeTokens(
    background: palette.gradient.last,
    backgroundAlt: palette.gradient.first,
    foreground: palette.ink,
    muted: palette.ink.computeLuminance() > 0.5
        ? const Color(0xFFCEC8D8)
        : palette.muted,
    accent: palette.ink.computeLuminance() > 0.5
        ? const Color(0xFF8FE3CB)
        : const Color(0xFF176B60),
    surface: palette.glass,
  );
}
