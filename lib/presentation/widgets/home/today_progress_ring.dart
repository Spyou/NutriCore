import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';

class TodayProgressRing extends StatelessWidget {
  const TodayProgressRing({super.key});

  void _openNutrition() {
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().changeIndex(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<NutritionController>();
    final numberFormat = NumberFormat.decimalPattern();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openNutrition,
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                // Ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Obx(() {
                    final consumed = controller.totalCalories.value;
                    // Read burned so Obx reacts to Health Connect changes.
                    controller.activeCaloriesBurnedToday;
                    final goal = controller.effectiveCalorieGoal;
                    final progress = goal <= 0
                        ? 0.0
                        : (consumed / goal).clamp(0.0, 1.0);
                    return CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        trackColor: scheme.primary.withValues(alpha: 0.12),
                        fillColor: scheme.primary,
                        strokeWidth: 14,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              numberFormat.format(consumed.round()),
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                                letterSpacing: -1.2,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'kcal',
                              style: textTheme.labelMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final burned = controller.activeCaloriesBurnedToday;
                  final goal = controller.effectiveCalorieGoal;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'of ${numberFormat.format(goal.round())} today',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (burned > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '+${numberFormat.format(burned.round())} burned today',
                          textAlign: TextAlign.center,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.primary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _MacroPill(
                        label: 'Protein',
                        accent: scheme.primary,
                        valueListenable: () => controller.totalProteins.value,
                        goalListenable: () => controller.proteinGoal.value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroPill(
                        label: 'Carbs',
                        accent: scheme.tertiary,
                        valueListenable: () => controller.totalCarbs.value,
                        goalListenable: () => controller.carbGoal.value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MacroPill(
                        label: 'Fat',
                        accent: scheme.secondary,
                        valueListenable: () => controller.totalFats.value,
                        goalListenable: () => controller.fatGoal.value,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final Color accent;
  final double Function() valueListenable;
  final double Function() goalListenable;

  const _MacroPill({
    required this.label,
    required this.accent,
    required this.valueListenable,
    required this.goalListenable,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Obx(() {
            final value = valueListenable();
            return Text(
              '${value.round()}g',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            );
          }),
          const SizedBox(height: 2),
          Obx(() {
            final value = valueListenable();
            final goal = goalListenable();
            final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: accent.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweep = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth;
}
