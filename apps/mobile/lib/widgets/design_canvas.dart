import 'package:flutter/material.dart';

import '../theme/loop_theme.dart';

class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  static const double width = 390;
  static const double height = 844;

  final Widget child;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('design-canvas'),
      child: Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: context.loopColors.pageBackground,
        body: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              key: const ValueKey('design-canvas-content'),
              width: width,
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientPage extends StatelessWidget {
  const GradientPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.loopColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -0.45),
            end: Alignment(1, 0.45),
            colors: palette.gradient,
            stops: [0, 0.50, 0.95],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        palette.bottomScrim,
                      ],
                      stops: [0, 0.56, 1],
                    ),
                  ),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
