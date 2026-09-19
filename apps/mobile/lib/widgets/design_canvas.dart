import 'package:flutter/material.dart';

import '../theme/loop_theme.dart';

class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  static const double width = 390;
  static const double height = 844;

  final Widget child;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('design-canvas'),
      child: Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor ?? context.loopColors.pageBackground,
        body: SizedBox.expand(
          key: const ValueKey('design-canvas-content'),
          child: child,
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
      borderRadius: BorderRadius.circular(
        MediaQuery.sizeOf(context).width < 600 ? 32 : 0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1, -0.45),
            end: const Alignment(1, 0.45),
            colors: palette.gradient,
            stops: const [0, 0.50, 0.95],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
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
                    stops: const [0, 0.56, 1],
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
