import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';

class WaterPill extends StatelessWidget {
  const WaterPill({super.key});

  static const int _maxDots = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Water',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Obx(() {
                final current = controller.waterIntake.value.toInt();
                final goal = controller.waterGoal.value.toInt();
                return Text(
                  '$current of $goal',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final current = controller.waterIntake.value.toInt();
            final goal = controller.waterGoal.value.toInt();
            final dotCount = goal <= 0
                ? 0
                : (goal > _maxDots ? _maxDots : goal);
            final overflowCount = goal > _maxDots
                ? (current - (_maxDots - 1)).clamp(0, 999)
                : 0;

            return Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < dotCount; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: i == dotCount - 1 ? 0 : 6,
                          ),
                          child: _GlassDot(
                            filled: i < current,
                            isLastWithOverflow:
                                i == dotCount - 1 &&
                                goal > _maxDots &&
                                overflowCount > 1,
                            overflowCount: overflowCount,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (i < current) {
                                if (i == current - 1) {
                                  controller.removeWater();
                                }
                              } else {
                                final needed = (i + 1) - current;
                                for (int n = 0; n < needed; n++) {
                                  controller.addWater();
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.addWater();
                    },
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: scheme.onPrimary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '1',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

class _GlassDot extends StatelessWidget {
  final bool filled;
  final bool isLastWithOverflow;
  final int overflowCount;
  final VoidCallback onTap;

  const _GlassDot({
    required this.filled,
    required this.isLastWithOverflow,
    required this.overflowCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget dot = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.7),
                ],
              )
            : null,
        border: filled
            ? null
            : Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      alignment: Alignment.center,
      child: filled
          ? (isLastWithOverflow
                ? Text(
                    '+$overflowCount',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  )
                : Icon(
                    Icons.water_drop_rounded,
                    size: 12,
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                  ))
          : null,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: dot,
    );
  }
}
