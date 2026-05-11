import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:nutri_check/domain/entities/meal_entry.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';
import 'package:nutri_check/presentation/pages/home/ai_meal_analysis_page.dart';

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key});

  String _buildInsight(NutritionController c) {
    final now = DateTime.now();
    final hour = now.hour;
    final meals = c.todayMeals;

    if (meals.isEmpty) {
      if (hour < 10) {
        return 'Start your day right. Snap your breakfast and AI will log it for you.';
      }
      if (hour < 17) {
        return 'Nothing logged yet today. Just snap a photo — AI will handle the rest.';
      }
      return 'No meals tracked today. A quick photo is all the AI needs.';
    }

    MealEntry? lastMeal;
    for (final m in meals) {
      if (lastMeal == null || m.timestamp.isAfter(lastMeal.timestamp)) {
        lastMeal = m;
      }
    }
    final hoursSinceLast =
        now.difference(lastMeal!.timestamp).inMinutes / 60.0;

    if (hoursSinceLast > 4 && hour >= 7 && hour <= 21) {
      final h = hoursSinceLast.floor();
      return '${h}h since your last meal. Snap your next bite to stay on track.';
    }

    if (hour >= 14 &&
        c.proteinGoal.value > 0 &&
        c.totalProteins.value < c.proteinGoal.value * 0.4) {
      final gap = (c.proteinGoal.value - c.totalProteins.value).clamp(0, 9999);
      final gapStr = NumberFormat.decimalPattern().format(gap.round());
      return "You're ${gapStr}g short on protein today. AI can analyse your plate in seconds.";
    }

    if (hoursSinceLast >= 3) {
      return "You're on track. Capture your next meal to keep momentum.";
    }

    return 'Snap a meal photo and let AI break down the nutrition for you.';
  }

  void _open() {
    HapticFeedback.selectionClick();
    Get.to(() => const AIMealAnalysisPage());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.45),
            scheme.tertiaryContainer.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: scheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  "Today's insight",
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final text = _buildInsight(controller);
            // touch reactives so Obx rebuilds when they change
            controller.totalProteins.value;
            controller.proteinGoal.value;
            controller.todayMeals.length;
            return Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            );
          }),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _open,
              child: Ink(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: scheme.onPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Snap a meal',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: scheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
