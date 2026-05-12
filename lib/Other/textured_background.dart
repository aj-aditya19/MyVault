import 'dart:math' as math;

import 'package:flutter/material.dart';

class TexturedBackground extends StatefulWidget {
  final Widget child;

  const TexturedBackground({super.key, required this.child});

  @override
  State<TexturedBackground> createState() => _TexturedBackgroundState();
}

class _TexturedBackgroundState extends State<TexturedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final drift = (_controller.value - 0.5) * 30;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0B1220),
                      Color(0xFF121A2C),
                      Color(0xFF0F172A),
                    ]
                  : const [
                      Color(0xFFF9FCFF),
                      Color(0xFFEAF6FF),
                      Color(0xFFF6F7FB),
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120 + drift,
                left: -90,
                child: _AuraOrb(
                  size: 250,
                  color: isDark
                      ? const Color(0xFF06B6D4)
                      : const Color(0xFF67E8F9),
                ),
              ),
              Positioned(
                right: -110,
                bottom: -100 - drift,
                child: _AuraOrb(
                  size: 280,
                  color: isDark
                      ? const Color(0xFF22D3EE)
                      : const Color(0xFF38BDF8),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _NoisePatternPainter(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFF1E293B).withValues(alpha: 0.045),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _AuraOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AuraOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _NoisePatternPainter extends CustomPainter {
  final Color color;

  _NoisePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    const spacing = 24.0;
    const radius = 0.85;

    for (double y = 0; y <= size.height; y += spacing) {
      for (double x = 0; x <= size.width; x += spacing) {
        final offset = math.sin((x + y) * 0.07) * 1.8;
        canvas.drawCircle(Offset(x + offset, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
