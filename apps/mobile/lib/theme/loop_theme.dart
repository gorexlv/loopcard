import 'package:flutter/material.dart';

@immutable
class LoopPalette extends ThemeExtension<LoopPalette> {
  const LoopPalette({
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.pageBackground,
    required this.glass,
    required this.glassStrong,
    required this.border,
    required this.divider,
    required this.inactive,
    required this.gradient,
    required this.bottomScrim,
  });

  final Color ink;
  final Color muted;
  final Color subtle;
  final Color pageBackground;
  final Color glass;
  final Color glassStrong;
  final Color border;
  final Color divider;
  final Color inactive;
  final List<Color> gradient;
  final Color bottomScrim;

  @override
  LoopPalette copyWith({
    Color? ink,
    Color? muted,
    Color? subtle,
    Color? pageBackground,
    Color? glass,
    Color? glassStrong,
    Color? border,
    Color? divider,
    Color? inactive,
    List<Color>? gradient,
    Color? bottomScrim,
  }) => LoopPalette(
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    subtle: subtle ?? this.subtle,
    pageBackground: pageBackground ?? this.pageBackground,
    glass: glass ?? this.glass,
    glassStrong: glassStrong ?? this.glassStrong,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    inactive: inactive ?? this.inactive,
    gradient: gradient ?? this.gradient,
    bottomScrim: bottomScrim ?? this.bottomScrim,
  );

  @override
  LoopPalette lerp(covariant LoopPalette? other, double t) {
    if (other == null) return this;
    return LoopPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      gradient: List.generate(
        gradient.length,
        (index) => Color.lerp(gradient[index], other.gradient[index], t)!,
      ),
      bottomScrim: Color.lerp(bottomScrim, other.bottomScrim, t)!,
    );
  }
}

extension LoopPaletteContext on BuildContext {
  LoopPalette get loopColors =>
      Theme.of(this).extension<LoopPalette>() ?? LoopTheme.darkPalette;
}

class LoopTheme {
  const LoopTheme._();

  static const Color ink = Color(0xFFF5F2FA);
  static const Color muted = Color(0xFFBDB8C7);
  static const Color teal = Color(0xFF2BBAA1);
  static const Color amber = Color(0xFFF09C0D);
  static const Color coral = Color(0xFFDB4257);

  static const darkPalette = LoopPalette(
    ink: ink,
    muted: muted,
    subtle: Color(0xFFAAA5B3),
    pageBackground: Colors.black,
    glass: Color(0x1FFFFFFF),
    glassStrong: Color(0x75171621),
    border: Color(0x14FFFFFF),
    divider: Color(0x24FFFFFF),
    inactive: Color(0xFFBAB8C2),
    gradient: [Color(0xFF333357), Color(0xFF422933), Color(0xFF0E0D13)],
    bottomScrim: Color(0x8A09080D),
  );

  static const lightPalette = LoopPalette(
    ink: Color(0xFF211E2B),
    muted: Color(0xFF6E6879),
    subtle: Color(0xFF817A8D),
    pageBackground: Color(0xFFEDE9F2),
    glass: Color(0xB8FFFFFF),
    glassStrong: Color(0xE8FFFFFF),
    border: Color(0x407D738B),
    divider: Color(0x24746980),
    inactive: Color(0xFF777080),
    gradient: [Color(0xFFE5E2F3), Color(0xFFF1E4E8), Color(0xFFF7F5F9)],
    bottomScrim: Color(0x18A99EAD),
  );

  static ThemeData get dark => _build(Brightness.dark, darkPalette);
  static ThemeData get light => _build(Brightness.light, lightPalette);
  static ThemeData get data => dark;

  static ThemeData _build(Brightness brightness, LoopPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: brightness,
      primary: teal,
      secondary: amber,
      surface: brightness == Brightness.dark
          ? const Color(0xFF171621)
          : const Color(0xFFF7F4F9),
      error: coral,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.pageBackground,
      fontFamily: 'NotoSansSC',
      splashFactory: NoSplash.splashFactory,
      extensions: [palette],
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: palette.ink, height: 1.45),
      ),
    );
  }
}
