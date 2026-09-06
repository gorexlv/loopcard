import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/design_canvas.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 1900),
  });

  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markFade;
  late final Animation<double> _markScale;
  late final Animation<Offset> _copyOffset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _markFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.58, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _copyOffset = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.38, 1, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
    _timer = Timer(widget.duration, widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: GradientPage(
        children: [
          Positioned.fill(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _markFade,
                      child: ScaleTransition(
                        scale: _markScale,
                        child: const BrandMark(size: 154, radius: 38),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _controller,
                      child: SlideTransition(
                        position: _copyOffset,
                        child: Column(
                          children: [
                            Text(
                              'LoopCard',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 35,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1,
                                color: context.loopColors.ink,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              context.l10n.tr('tagline'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                color: context.loopColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
