import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_visuals.dart';

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
    final tokens = CardThemeTokens.forFamily(family);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.backgroundAlt, tokens.background],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _CardMotifPainter(family, tokens)),
          if (mood == CardMood.quiet)
            ColoredBox(color: tokens.background.withValues(alpha: 0.2)),
          if (mood == CardMood.vivid)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.85),
                  radius: 0.9,
                  colors: [
                    tokens.accent.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  tokens.background.withValues(alpha: 0.34),
                ],
                stops: const [0.38, 1],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CardMotifPainter extends CustomPainter {
  const _CardMotifPainter(this.family, this.tokens);

  final CardThemeFamily family;
  final CardThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = Paint()
      ..color = tokens.accent.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final faint = Paint()
      ..color = tokens.foreground.withValues(alpha: 0.075)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    switch (family) {
      case CardThemeFamily.paper:
        for (var y = 14.0; y < size.height; y += 13) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), faint);
        }
        canvas.drawCircle(Offset(size.width * 0.88, 76), 92, accent);
      case CardThemeFamily.lab:
        for (var x = 0.0; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), faint);
        }
        for (var y = 0.0; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), faint);
        }
        canvas.drawCircle(Offset(size.width * 0.83, 92), 62, accent);
        canvas.drawCircle(Offset(size.width * 0.83, 92), 33, accent);
      case CardThemeFamily.cosmos:
        for (var i = 0; i < 25; i++) {
          final x = ((i * 83) % 337) / 337 * size.width;
          final y = ((i * 47) % 461) / 461 * size.height;
          canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 1.4 : 0.7, accent);
        }
        canvas.drawArc(
          Rect.fromCircle(center: Offset(size.width * 0.86, 80), radius: 86),
          math.pi * 0.15,
          math.pi * 1.5,
          false,
          accent,
        );
      case CardThemeFamily.botanical:
        final path = Path()
          ..moveTo(size.width, 40)
          ..cubicTo(
            size.width * 0.68,
            72,
            size.width * 0.84,
            180,
            size.width * 0.56,
            242,
          )
          ..cubicTo(
            size.width * 0.32,
            302,
            size.width * 0.5,
            390,
            size.width * 0.18,
            size.height,
          );
        canvas.drawPath(path, accent..strokeWidth = 2);
        for (var i = 0; i < 5; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(size.width - 46.0 - i * 30, 108.0 + i * 66),
              width: 55,
              height: 22,
            ),
            faint,
          );
        }
      case CardThemeFamily.mono:
        canvas.drawRect(
          Rect.fromLTWH(size.width - 82, 0, 1, size.height),
          faint,
        );
        canvas.drawLine(
          Offset(0, size.height * 0.72),
          Offset(size.width, size.height * 0.72),
          accent,
        );
        canvas.drawCircle(
          Offset(size.width - 42, 42),
          8,
          accent..style = PaintingStyle.fill,
        );
      case CardThemeFamily.aurora:
        final glow = Paint()
          ..shader =
              RadialGradient(
                colors: [
                  tokens.accent.withValues(alpha: 0.32),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.82, 80),
                  radius: 170,
                ),
              );
        canvas.drawCircle(Offset(size.width * 0.82, 80), 170, glow);
        canvas.drawArc(
          Rect.fromLTWH(-80, size.height * 0.45, size.width * 1.45, 190),
          math.pi * 1.08,
          math.pi * 0.74,
          false,
          accent..strokeWidth = 2,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CardMotifPainter oldDelegate) =>
      oldDelegate.family != family || oldDelegate.tokens != tokens;
}
