import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/design_canvas.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 1400),
  });

  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _motionStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _timer = Timer(widget.duration, widget.onFinished);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionStarted) return;
    _motionStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'LoopCard. ${context.l10n.tr('tagline')}',
      child: ExcludeSemantics(
        child: DesignCanvas(
          backgroundColor: const Color(0xFF313153),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                final atmosphere = _interval(value, 0, 0.46);
                final stack = Curves.easeOutCubic.transform(
                  _interval(value, 0.06, 0.48),
                );
                final trace = Curves.easeOutCubic.transform(
                  _interval(value, 0.18, 0.70),
                );
                final mark = Curves.easeOutCubic.transform(
                  _interval(value, 0.14, 0.62),
                );
                final copy = Curves.easeOutCubic.transform(
                  _interval(value, 0.44, 0.84),
                );

                return ColoredBox(
                  color: const Color(0xFF313153),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: atmosphere,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1, -0.55),
                                end: Alignment(1, 0.65),
                                colors: [
                                  Color(0xFF333357),
                                  Color(0xFF422933),
                                  Color(0xFF0E0D13),
                                ],
                                stops: [0, 0.52, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Opacity(
                          key: const ValueKey('splash-paper-field'),
                          opacity: 0.30 * atmosphere,
                          child: const CustomPaint(
                            painter: _SplashPaperFieldPainter(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        right: 30,
                        top: 202,
                        height: 360,
                        child: Transform.translate(
                          offset: Offset(0, 28 * (1 - stack)),
                          child: Opacity(
                            key: const ValueKey('splash-stack-opacity'),
                            opacity: stack,
                            child: Stack(
                              key: const ValueKey('splash-card-stack'),
                              alignment: Alignment.center,
                              children: [
                                _MemorySheet(
                                  key: const ValueKey(
                                    'splash-memory-sheet-back',
                                  ),
                                  color: const Color(0xFF565071),
                                  width: 218,
                                  height: 274,
                                  angle: _lerp(-0.20, -0.105, stack),
                                  offset: Offset(
                                    _lerp(-46, -25, stack),
                                    _lerp(14, 2, stack),
                                  ),
                                ),
                                _MemorySheet(
                                  key: const ValueKey(
                                    'splash-memory-sheet-middle',
                                  ),
                                  color: const Color(0xFF704556),
                                  width: 222,
                                  height: 278,
                                  angle: _lerp(0.18, 0.09, stack),
                                  offset: Offset(
                                    _lerp(48, 25, stack),
                                    _lerp(20, 5, stack),
                                  ),
                                ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    key: const ValueKey('splash-loop-trace'),
                                    painter: _LoopTracePainter(progress: trace),
                                  ),
                                ),
                                _MemorySheet(
                                  key: const ValueKey(
                                    'splash-memory-sheet-front',
                                  ),
                                  color: const Color(0xFFF7F3EB),
                                  width: 230,
                                  height: 286,
                                  angle: _lerp(-0.025, 0, stack),
                                  offset: Offset(0, _lerp(18, 0, stack)),
                                  isFront: true,
                                  child: Transform.scale(
                                    scale: _lerp(0.74, 1, mark),
                                    child: Opacity(
                                      opacity: mark,
                                      child: const BrandMark(
                                        size: 104,
                                        radius: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 32,
                        right: 32,
                        top: 576,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - copy)),
                          child: Opacity(
                            key: const ValueKey('splash-copy-opacity'),
                            opacity: copy,
                            child: Column(
                              children: [
                                const Text(
                                  'LoopCard',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 41,
                                    height: 1.08,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.5,
                                    color: Color(0xFFF8F5FB),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  context.l10n.tr('tagline'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 2.1,
                                    color: Color(0xFFC4BDCE),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const _MemorySignature(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

double _interval(double value, double begin, double end) {
  return ((value - begin) / (end - begin)).clamp(0, 1);
}

double _lerp(double begin, double end, double progress) {
  return begin + (end - begin) * progress;
}

class _MemorySheet extends StatelessWidget {
  const _MemorySheet({
    super.key,
    required this.color,
    required this.width,
    required this.height,
    required this.angle,
    required this.offset,
    this.isFront = false,
    this.child,
  });

  final Color color;
  final double width;
  final double height;
  final double angle;
  final Offset offset;
  final bool isFront;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isFront
                  ? const Color(0xFFE1DBD2)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isFront ? 0.24 : 0.16),
                blurRadius: isFront ? 34 : 20,
                offset: Offset(0, isFront ? 18 : 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: isFront
              ? CustomPaint(
                  painter: const _FrontSheetPainter(),
                  child: Center(child: child),
                )
              : child,
        ),
      ),
    );
  }
}

class _MemorySignature extends StatelessWidget {
  const _MemorySignature();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _SignatureBar(color: LoopTheme.teal, width: 30),
        SizedBox(width: 5),
        _SignatureBar(color: LoopTheme.amber, width: 18),
        SizedBox(width: 5),
        _SignatureBar(color: LoopTheme.coral, width: 10),
      ],
    );
  }
}

class _SignatureBar extends StatelessWidget {
  const _SignatureBar({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SplashPaperFieldPainter extends CustomPainter {
  const _SplashPaperFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFBBB5CD).withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (double y = 92; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = LoopTheme.coral.withValues(alpha: 0.24)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(46, 0), Offset(46, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _SplashPaperFieldPainter oldDelegate) => false;
}

class _FrontSheetPainter extends CustomPainter {
  const _FrontSheetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF5A5771).withValues(alpha: 0.09)
      ..strokeWidth = 1;
    for (double y = 45; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = LoopTheme.coral.withValues(alpha: 0.34)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(31, 0), Offset(31, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _FrontSheetPainter oldDelegate) => false;
}

class _LoopTracePainter extends CustomPainter {
  const _LoopTracePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final halfWidth = size.width * 0.49;
    final halfHeight = size.height * 0.18;
    const steps = 180;
    for (var index = 0; index <= steps; index++) {
      final t = index / steps * math.pi * 2;
      final denominator = 1 + math.pow(math.sin(t), 2);
      final point = Offset(
        center.dx + halfWidth * math.cos(t) / denominator,
        center.dy + halfHeight * math.sin(t) * math.cos(t) / denominator,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final metric = path.computeMetrics().first;
    final length = metric.length * progress;
    final tracedPath = metric.extractPath(0, length);
    final tracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [LoopTheme.teal, LoopTheme.amber, LoopTheme.coral],
      ).createShader(Offset.zero & size);
    canvas.drawPath(tracedPath, tracePaint);

    final tangent = metric.getTangentForOffset(length.clamp(0, metric.length));
    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        3.8,
        Paint()..color = Color.lerp(LoopTheme.teal, LoopTheme.coral, progress)!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoopTracePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
