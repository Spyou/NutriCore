import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';

/// A richer "today" hero card for the Nutrition tab. Same visual language
/// as `TodayProgressRing` (ring + macro pills) but with three extra info
/// pieces: remaining calories, day-over-day delta, and a 7-day sparkline.
class NutritionTodayCard extends StatelessWidget {
  const NutritionTodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<NutritionController>();
    final numberFormat = NumberFormat.decimalPattern();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Hero row ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Obx(() {
                  final consumed = controller.totalCalories.value;
                  final goal = controller.calorieGoal.value;
                  final progress = goal <= 0
                      ? 0.0
                      : (consumed / goal).clamp(0.0, 1.0);
                  return CustomPaint(
                    painter: _RingPainter(
                      progress: progress,
                      trackColor: scheme.primary.withValues(alpha: 0.12),
                      fillColor: scheme.primary,
                      strokeWidth: 12,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            numberFormat.format(consumed.round()),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'kcal',
                            style: textTheme.labelSmall?.copyWith(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final consumed = controller.totalCalories.value;
                      return Text(
                        numberFormat.format(consumed.round()),
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          letterSpacing: -1.2,
                          height: 1.0,
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                    Obx(() {
                      final goal = controller.calorieGoal.value;
                      return Text(
                        'of ${numberFormat.format(goal.round())} today',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final consumed = controller.totalCalories.value;
                      final goal = controller.calorieGoal.value;
                      final over = consumed > goal;
                      final remaining = over
                          ? (consumed - goal)
                          : (goal - consumed);
                      final label = over ? 'Over by' : 'Remaining';
                      final accent = over ? scheme.error : scheme.primary;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${numberFormat.format(remaining.round())} kcal',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),

          Divider(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            height: 24,
          ),

          // ── 2. Macro pills ──────────────────────────────────────────
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

          Divider(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            height: 24,
          ),

          // ── 3. Sparkline section ────────────────────────────────────
          Obx(() {
            final week = controller.weekCalories.toList();
            final today = week.isNotEmpty ? week.last : 0.0;
            final yesterday = controller.yesterdayCalories.value;
            final trendIsUp = today >= yesterday;
            final trendColor = trendIsUp
                ? scheme.primary
                : scheme.error.withValues(alpha: 0.85);
            return Row(
              children: [
                Text(
                  'Last 7 days',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: trendColor,
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final week = controller.weekCalories.toList();
            final padded = week.length == 7
                ? week
                : List<double>.filled(7, 0.0);
            return SizedBox(
              height: 56,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: padded,
                  todayColor: scheme.primary,
                  pastColor: scheme.primary.withValues(alpha: 0.35),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          _DayLabelsRow(
            referenceDate: controller.selectedDate.value,
            color: scheme.onSurface.withValues(alpha: 0.6),
            todayColor: scheme.onSurface,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),

          // ── 4. Delta line ───────────────────────────────────────────
          Obx(() {
            final consumed = controller.totalCalories.value;
            final goal = controller.calorieGoal.value;
            final yesterday = controller.yesterdayCalories.value;
            final delta = consumed - yesterday;
            final fmt = NumberFormat.decimalPattern();

            IconData? icon;
            String text;
            Color color = scheme.onSurface.withValues(alpha: 0.65);

            if (yesterday == 0) {
              text = 'Nothing logged yesterday';
            } else if (delta > 0) {
              icon = Icons.arrow_drop_up_rounded;
              text = '${fmt.format(delta.round())} kcal more than yesterday';
              color = consumed > goal
                  ? scheme.error
                  : scheme.onSurface.withValues(alpha: 0.65);
            } else if (delta < 0) {
              icon = Icons.arrow_drop_down_rounded;
              text =
                  '${fmt.format(delta.abs().round())} kcal less than yesterday';
              color = scheme.primary;
            } else {
              text = 'Same as yesterday';
            }

            return Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: color),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
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

class _DayLabelsRow extends StatelessWidget {
  final DateTime referenceDate;
  final Color color;
  final Color todayColor;
  final TextTheme textTheme;

  const _DayLabelsRow({
    required this.referenceDate,
    required this.color,
    required this.todayColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final fmt = DateFormat('E');
    final labels = <_DayLabel>[];
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: 6 - i));
      final letter = fmt.format(date).substring(0, 1).toUpperCase();
      labels.add(_DayLabel(letter: letter, isToday: i == 6));
    }
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(
                l.letter,
                style: textTheme.labelSmall?.copyWith(
                  color: l.isToday ? todayColor : color,
                  fontWeight: l.isToday ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayLabel {
  final String letter;
  final bool isToday;
  const _DayLabel({required this.letter, required this.isToday});
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color todayColor;
  final Color pastColor;

  _SparklinePainter({
    required this.values,
    required this.todayColor,
    required this.pastColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const barWidth = 16.0;
    final count = values.length;
    final slot = size.width / count;
    final maxVal = values.fold<double>(0.0, math.max);

    for (int i = 0; i < count; i++) {
      final v = values[i];
      final double h;
      if (maxVal <= 0) {
        h = 4.0;
      } else {
        h = (v / maxVal) * size.height;
      }
      final clampedH = h.clamp(2.0, size.height);
      final isToday = i == count - 1;
      final color = isToday ? todayColor : pastColor;
      final left = slot * i + (slot - barWidth) / 2;
      final top = size.height - clampedH;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, clampedH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      final paint = Paint()..color = color;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.todayColor != todayColor ||
      old.pastColor != pastColor;
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
