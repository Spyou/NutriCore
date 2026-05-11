import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedAuthBackground extends StatelessWidget {
  final Widget child;

  const AnimatedAuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(child: Container(color: scheme.surface)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RadialAccentPainter(
                primary: scheme.primary,
                tertiary: scheme.tertiary,
                isDark: isDark,
              ),
            ),
          ),
        ),
        if (isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GrainPainter(
                  scheme.onSurface.withValues(alpha: 0.025),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _RadialAccentPainter extends CustomPainter {
  final Color primary;
  final Color tertiary;
  final bool isDark;

  _RadialAccentPainter({
    required this.primary,
    required this.tertiary,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryAlpha = isDark ? 0.10 : 0.09;
    final tertiaryAlpha = isDark ? 0.05 : 0.05;

    // Top-left primary accent
    final tlCenter = Offset(size.width * 0.1, size.height * 0.08);
    final tlRadius = size.width * 0.9;
    final tlShader = RadialGradient(
      colors: [primary.withValues(alpha: primaryAlpha), primary.withValues(alpha: 0)],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: tlCenter, radius: tlRadius));
    canvas.drawRect(Offset.zero & size, Paint()..shader = tlShader);

    // Subtle bottom-right tertiary accent
    final brCenter = Offset(size.width * 0.95, size.height * 0.85);
    final brRadius = size.width * 0.7;
    final brShader = RadialGradient(
      colors: [tertiary.withValues(alpha: tertiaryAlpha), tertiary.withValues(alpha: 0)],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: brCenter, radius: brRadius));
    canvas.drawRect(Offset.zero & size, Paint()..shader = brShader);
  }

  @override
  bool shouldRepaint(covariant _RadialAccentPainter old) =>
      old.primary != primary ||
      old.tertiary != tertiary ||
      old.isDark != isDark;
}

class _GrainPainter extends CustomPainter {
  final Color color;
  _GrainPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = color;
    final count = (size.width * size.height / 700).round();
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.color != color;
}
