import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';

class BmiIndicator extends StatelessWidget {
  const BmiIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<ProfileController>();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'BMI',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Obx(() {
                // Read reactive deps to trigger rebuild.
                controller.height.value;
                controller.currentWeight.value;
                final bmi = controller.bmi;
                return Text(
                  bmi.toStringAsFixed(1),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                );
              }),
              const SizedBox(width: 8),
              Obx(() {
                controller.height.value;
                controller.currentWeight.value;
                final category = controller.bmiCategory;
                final (bg, fg) = _categoryColors(scheme, category);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _categoryLabel(category),
                    style: textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            controller.height.value;
            controller.currentWeight.value;
            final bmi = controller.bmi;
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 14,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BmiBarPainter(
                    bmi: bmi,
                    underweightColor: scheme.tertiary.withValues(alpha: 0.3),
                    healthyColor: scheme.primary.withValues(alpha: 0.3),
                    overweightColor: scheme.secondary.withValues(alpha: 0.3),
                    obeseColor: scheme.error.withValues(alpha: 0.3),
                    markerColor: scheme.onSurface,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          _rangeLabels(scheme, textTheme),
          const SizedBox(height: 6),
          Text(
            'Healthy range: 18.5 - 25.0',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeLabels(ColorScheme scheme, TextTheme textTheme) {
    final labels = ['15', '18.5', '25', '30+'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final l in labels)
          Text(
            l,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  String _categoryLabel(String raw) {
    // Normalise "Normal" -> "Healthy"
    if (raw.toLowerCase() == 'normal') return 'Healthy';
    return raw;
  }

  (Color, Color) _categoryColors(ColorScheme scheme, String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return (
          scheme.tertiary.withValues(alpha: 0.18),
          scheme.tertiary,
        );
      case 'normal':
      case 'healthy':
        return (
          scheme.primary.withValues(alpha: 0.18),
          scheme.primary,
        );
      case 'overweight':
        return (
          scheme.secondary.withValues(alpha: 0.18),
          scheme.secondary,
        );
      case 'obese':
        return (
          scheme.error.withValues(alpha: 0.18),
          scheme.error,
        );
      default:
        return (
          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          scheme.onSurface,
        );
    }
  }
}

class _BmiBarPainter extends CustomPainter {
  final double bmi;
  final Color underweightColor;
  final Color healthyColor;
  final Color overweightColor;
  final Color obeseColor;
  final Color markerColor;

  _BmiBarPainter({
    required this.bmi,
    required this.underweightColor,
    required this.healthyColor,
    required this.overweightColor,
    required this.obeseColor,
    required this.markerColor,
  });

  static const double _minBmi = 15.0;
  static const double _maxBmi = 40.0;

  double _xFor(double value, double width) {
    final t = ((value - _minBmi) / (_maxBmi - _minBmi)).clamp(0.0, 1.0);
    return t * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 4 segments by BMI thresholds.
    final under = Rect.fromLTRB(0, 0, _xFor(18.5, w), h);
    final healthy = Rect.fromLTRB(_xFor(18.5, w), 0, _xFor(25, w), h);
    final over = Rect.fromLTRB(_xFor(25, w), 0, _xFor(30, w), h);
    final obese = Rect.fromLTRB(_xFor(30, w), 0, w, h);

    canvas.drawRect(under, Paint()..color = underweightColor);
    canvas.drawRect(healthy, Paint()..color = healthyColor);
    canvas.drawRect(over, Paint()..color = overweightColor);
    canvas.drawRect(obese, Paint()..color = obeseColor);

    if (bmi > 0) {
      final markerX = _xFor(bmi, w);
      const markerW = 4.0;
      final left = (markerX - markerW / 2).clamp(0.0, w - markerW);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, markerW, h),
          const Radius.circular(2),
        ),
        Paint()..color = markerColor,
      );
    }
  }

  @override
  bool shouldRepaint(_BmiBarPainter old) =>
      old.bmi != bmi ||
      old.underweightColor != underweightColor ||
      old.healthyColor != healthyColor ||
      old.overweightColor != overweightColor ||
      old.obeseColor != obeseColor ||
      old.markerColor != markerColor;
}
