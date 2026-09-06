import 'package:flutter/material.dart';

import '../theme/loop_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.22),
      child: Image.asset(
        'assets/brand/loopcard-app-icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.markSize = 26,
    this.fontSize = 18,
    this.color,
  });

  final double markSize;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: 9),
        Text(
          'LoopCard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.35,
            color: color ?? context.loopColors.ink,
          ),
        ),
      ],
    );
  }
}
