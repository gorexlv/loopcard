import 'package:flutter/material.dart';

import '../models/card_models.dart';

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
      theme: preferences.theme ?? _themeFor(kind),
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

  CardThemeFamily _themeFor(CardKind kind) => switch (kind) {
    CardKind.word => CardThemeFamily.paper,
    CardKind.formula => CardThemeFamily.lab,
    CardKind.problem => CardThemeFamily.mono,
  };

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

  static CardThemeTokens forFamily(CardThemeFamily family) => switch (family) {
    CardThemeFamily.aurora => const CardThemeTokens(
      background: Color(0xFF10152D),
      backgroundAlt: Color(0xFF34305F),
      foreground: Color(0xFFF7F3FF),
      muted: Color(0xFFC9C3DD),
      accent: Color(0xFF8FE3CB),
      surface: Color(0x261F2744),
    ),
    CardThemeFamily.paper => const CardThemeTokens(
      background: Color(0xFFF0E7D5),
      backgroundAlt: Color(0xFFD8C9AC),
      foreground: Color(0xFF211C16),
      muted: Color(0xFF655D51),
      accent: Color(0xFFB0442F),
      surface: Color(0x66FFFDF7),
    ),
    CardThemeFamily.cosmos => const CardThemeTokens(
      background: Color(0xFF080B18),
      backgroundAlt: Color(0xFF1B2347),
      foreground: Color(0xFFF2F4FF),
      muted: Color(0xFFB5BCDC),
      accent: Color(0xFFFFC66E),
      surface: Color(0x263A456D),
    ),
    CardThemeFamily.lab => const CardThemeTokens(
      background: Color(0xFF092A31),
      backgroundAlt: Color(0xFF164751),
      foreground: Color(0xFFF0FBF8),
      muted: Color(0xFFB8D4D1),
      accent: Color(0xFFFFC857),
      surface: Color(0x263D7C7C),
    ),
    CardThemeFamily.botanical => const CardThemeTokens(
      background: Color(0xFF15251E),
      backgroundAlt: Color(0xFF425B48),
      foreground: Color(0xFFF4F2E7),
      muted: Color(0xFFC7CDBF),
      accent: Color(0xFFE8B975),
      surface: Color(0x263F5948),
    ),
    CardThemeFamily.mono => const CardThemeTokens(
      background: Color(0xFF111111),
      backgroundAlt: Color(0xFF333333),
      foreground: Color(0xFFF7F4EC),
      muted: Color(0xFFC7C3BA),
      accent: Color(0xFFE85D3F),
      surface: Color(0x26FFFFFF),
    ),
  };
}
