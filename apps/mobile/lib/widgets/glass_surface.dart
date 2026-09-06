import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/loop_theme.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    required this.radius,
    this.color,
    this.borderColor,
    this.blur = 12,
    this.shadow,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double blur;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.loopColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? palette.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? palette.border),
            boxShadow: shadow == null ? null : [shadow!],
          ),
          child: child,
        ),
      ),
    );
  }
}
