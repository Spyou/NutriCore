import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nutri_check/domain/entities/meal_entry.dart';
import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';
import 'package:nutri_check/presentation/widgets/shared/meal_type_helpers.dart';

class TodayMealsList extends StatelessWidget {
  const TodayMealsList({super.key});

  void _goToNutritionTab() {
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().changeIndex(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _goToNutritionTab,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final meals = controller.todayMeals.toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (meals.isEmpty) {
              return const _EmptyState();
            }

            final visible = meals.take(4).toList();
            final dividerColor = scheme.outlineVariant.withValues(alpha: 0.35);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < visible.length; i++) ...[
                  _MealRow(meal: visible[i], onTap: _goToNutritionTab),
                  if (i != visible.length - 1)
                    Divider(height: 24, color: dividerColor),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onTap;

  const _MealRow({required this.meal, required this.onTap});

  Color _tintFor(MealType type, ColorScheme scheme) {
    switch (type) {
      case MealType.breakfast:
        return scheme.tertiary;
      case MealType.lunch:
        return scheme.primary;
      case MealType.dinner:
        return scheme.secondary;
      case MealType.snack:
        return scheme.primary;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeStr = DateFormat('h:mm a').format(meal.timestamp);
    final tint = _tintFor(meal.type, scheme);
    final typeLabel = _capitalize(meal.type.name);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                MealTypeHelpers.getIcon(meal.type),
                size: 24,
                color: tint,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    meal.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$typeLabel · $timeStr',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${meal.calories.toInt()} kcal',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 38,
            color: scheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing logged yet today',
            style: textTheme.titleSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Log meal" below to get started',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
