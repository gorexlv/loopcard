import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/loop_theme.dart';
import 'card_visuals.dart';

/// One shared material for study cards, generated cards and chat previews.
/// Legacy family/mood values remain readable but no longer change the palette.
class CardBackground extends StatelessWidget {
  const CardBackground({
    super.key,
    required this.family,
    required this.mood,
    required this.child,
  });
  final CardThemeFamily family;
  final CardMood mood;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.loopColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.gradient[0].withValues(alpha: 0.88),
                palette.gradient[1].withValues(alpha: 0.88),
                palette.gradient[2].withValues(alpha: 0.94),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.20 : 0.8),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.12 : 0.60),
                  Colors.white.withValues(alpha: dark ? 0.025 : 0.18),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
