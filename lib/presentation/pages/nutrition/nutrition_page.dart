import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/domain/entities/meal_entry.dart';

import '../../controllers/nutrition_controller.dart';
import '../../widgets/home/today_progress_ring.dart';
import '../../widgets/nutrition/add_manual_meal_sheet.dart';
import '../../widgets/nutrition/log_meal_action_sheet.dart';
import '../../widgets/shared/meal_type_helpers.dart';

class NutritionPage extends GetView<NutritionController> {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.manualRefresh();
        },
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewModeToggle(context),
                    const SizedBox(height: 20),
                    const TodayProgressRing(),
                    const SizedBox(height: 20),
                    _buildWaterTracking(context),
                    const SizedBox(height: 20),
                    _buildMealFilters(context),
                    const SizedBox(height: 12),
                    _buildMealsList(context),
                    const SizedBox(height: 20),
                    _buildFavoriteMeals(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      expandedHeight: 120,
      toolbarHeight: 44,
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double top = constraints.biggest.height;
          final double collapsedHeight =
              MediaQuery.of(context).padding.top + 44;
          final double expandedHeight =
              120 + MediaQuery.of(context).padding.top;
          final double shrinkOffset = (expandedHeight - top).clamp(
            0.0,
            expandedHeight - collapsedHeight,
          );
          final double shrinkPercentage =
              (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(
                0.0,
                1.0,
              );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.only(
                left: 20,
                bottom: 0 + (8 * shrinkPercentage),
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: shrinkPercentage > 0.5
                    ? Text(
                        'Nutrition',
                        key: const ValueKey('collapsed'),
                        style: textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 80,
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (shrinkPercentage < 0.5) ...[
                        Text(
                          'Nutrition Tracker',
                          style: textTheme.headlineMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 120,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Obx(
                                  () => Text(
                                    _formatDate(controller.selectedDate.value),
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: scheme.onPrimary.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildDateNavigation(context),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        Obx(
          () => controller.isLoading.value
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: scheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          onPressed: () => _showMoreOptions(context),
          icon: Icon(Icons.more_vert, color: scheme.onPrimary),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }

  Widget _buildDateNavigation(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              controller.setSelectedDate(
                controller.selectedDate.value.subtract(const Duration(days: 1)),
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.chevron_left, color: scheme.onPrimary, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              controller.setSelectedDate(
                controller.selectedDate.value.add(const Duration(days: 1)),
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.chevron_right,
                color: scheme.onPrimary,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: ['daily', 'weekly', 'monthly'].map((mode) {
            final isSelected = controller.viewMode.value == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.changeViewMode(mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mode.capitalize!,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWaterTracking(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Water Intake',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  '${controller.waterIntake.value.toInt()}/${controller.waterGoal.value.toInt()} glasses',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          (controller.waterIntake.value /
                                  controller.waterGoal.value)
                              .clamp(0.0, 1.0),
                      backgroundColor: scheme.primary.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.removeWater,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: scheme.error,
                      iconSize: 28,
                    ),
                    IconButton(
                      onPressed: controller.addWater,
                      icon: const Icon(Icons.add_circle_outline),
                      color: scheme.primary,
                      iconSize: 28,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealFilters(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mealTypes = ['all', 'breakfast', 'lunch', 'dinner', 'snack'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Meals',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _showSearchDialog(context),
                  icon: const Icon(Icons.search, size: 20),
                ),
                IconButton(
                  onPressed: () => _showMealOptions(context),
                  icon: const Icon(Icons.filter_list, size: 20),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: mealTypes
                .map(
                  (type) => Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_getMealTypeLabel(type)),
                        selected: controller.selectedMealType.value == type,
                        onSelected: (_) => controller.filterByMealType(type),
                        selectedColor: scheme.primary,
                        labelStyle: textTheme.labelMedium?.copyWith(
                          color: controller.selectedMealType.value == type
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final meals = controller.filteredMeals;

      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: scheme.primary),
        );
      }

      if (meals.isEmpty) {
        return _buildEmptyMealsState(context);
      }

      return Column(
        children: meals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;
          return _buildMealCard(
            context,
            meal,
            index,
            controller.viewMode.value,
            controller,
          );
        }).toList(),
      );
    });
  }

  Widget _buildEmptyMealsState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 56,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No meals logged for this day',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your first meal to get started',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => LogMealActionSheet.show(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log a meal'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => controller.copyYesterdayMeals(),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Copy yesterday'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMealPeriodContext(MealEntry meal, String viewMode) {
    if (viewMode == 'weekly') {
      return _formatDate(meal.timestamp);
    } else if (viewMode == 'monthly') {
      return _formatDate(meal.timestamp);
    }
    return '';
  }

  Widget _buildMealCard(
    BuildContext context,
    MealEntry meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (viewMode != 'daily') {
      return _buildStaticMealCard(context, meal, index, viewMode, controller);
    }

    return Slidable(
      key: ValueKey(meal.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _openEditSheet(context, index, meal),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => controller.duplicateMeal(index),
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
            icon: Icons.copy,
            label: 'Copy',
          ),
          SlidableAction(
            onPressed: (slideCtx) async {
              final confirmed = await _showDeleteConfirmation(
                context,
                meal.name,
              );
              if (confirmed) {
                final deletedMealData = <String, dynamic>{
                  'name': meal.name,
                  'calories': meal.calories,
                  'proteins': meal.proteins,
                  'carbs': meal.carbs,
                  'fat': meal.fat,
                  'type': meal.type.name,
                  'notes': meal.notes,
                  'imageUrl': meal.imageUrl,
                  'isFavorite': meal.isFavorite,
                };
                controller.deleteMeal(index);
                if (!slideCtx.mounted) return;
                ScaffoldMessenger.of(slideCtx).showSnackBar(
                  SnackBar(
                    content: Text('${meal.name} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        controller.addMeal(deletedMealData);
                      },
                    ),
                  ),
                );
              }
            },
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(12),
            onPressed: (_) => controller.toggleFavorite({
              'name': meal.name,
              'calories': meal.calories,
              'proteins': meal.proteins,
              'carbs': meal.carbs,
              'fat': meal.fat,
              'type': meal.type.name,
            }),
            backgroundColor: meal.isFavorite
                ? scheme.surfaceContainerHighest
                : scheme.tertiary,
            foregroundColor: meal.isFavorite
                ? scheme.onSurface
                : scheme.onTertiary,
            icon: meal.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: meal.isFavorite ? 'Unfav' : 'Fav',
          ),
        ],
      ),
      child: _buildMealCardContent(context, meal, index, viewMode, controller),
    );
  }

  Widget _buildStaticMealCard(
    BuildContext context,
    MealEntry meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    return _buildMealCardContent(context, meal, index, viewMode, controller);
  }

  void _openEditSheet(BuildContext context, int index, MealEntry meal) {
    AddManualMealSheet.show(
      context,
      editIndex: index,
      existing: {
        'name': meal.name,
        'calories': meal.calories,
        'proteins': meal.proteins,
        'carbs': meal.carbs,
        'fat': meal.fat,
        'type': meal.type.name,
        'notes': meal.notes,
        'imageUrl': meal.imageUrl,
        'favorite': meal.isFavorite,
      },
    );
  }

  Widget _buildMealCardContent(
    BuildContext context,
    MealEntry meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = MealTypeHelpers.getColor(meal.type);
    final mealIcon = MealTypeHelpers.getIcon(meal.type);
    final imageUrl = meal.imageUrl;

    final Widget leading = (imageUrl == null || imageUrl.isEmpty)
        ? Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(mealIcon, color: accent, size: 24),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: accent.withValues(alpha: 0.12),
                  child: Icon(mealIcon, color: accent, size: 24),
                ),
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: viewMode == 'daily'
              ? () => _openEditSheet(context, index, meal)
              : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: meal.isFavorite
                    ? scheme.tertiary.withValues(alpha: 0.4)
                    : scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  meal.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              if (meal.isFavorite)
                                Icon(
                                  Icons.favorite,
                                  color: scheme.tertiary,
                                  size: 16,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${meal.calories.toInt()} kcal • P: ${meal.proteins.toInt()}g • C: ${meal.carbs.toInt()}g • F: ${meal.fat.toInt()}g',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          if (viewMode != 'daily') ...[
                            const SizedBox(height: 4),
                            Text(
                              _getMealPeriodContext(meal, viewMode),
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (viewMode == 'daily')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.swipe,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ),
                      ],
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

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String mealName,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.delete_outline, color: scheme.error, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Meal',
                    style: textTheme.titleLarge?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete this meal?',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: scheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mealName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This action cannot be undone.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildFavoriteMeals(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      if (controller.favoriteMeals.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorite Meals',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => controller.clearAllFavorites(),
                icon: Icon(
                  Icons.clear_all,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
                tooltip: 'Clear all favorites',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.favoriteMeals.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (cardCtx, index) {
                final meal = controller.favoriteMeals[index];
                return _buildFavoriteMealCard(cardCtx, meal);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFavoriteMealCard(
    BuildContext context,
    Map<String, dynamic> meal,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _addFavoriteToLog(meal),
      onLongPress: () => _showFavoriteMealOptions(context, meal),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: scheme.tertiary, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meal['name']?.toString() ?? '',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => controller.removeFromFavorites(meal),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${meal['calories']} kcal',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            Text(
              'P: ${meal['proteins']}g • C: ${meal['carbs']}g',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoriteMealOptions(
    BuildContext context,
    Map<String, dynamic> meal,
  ) {
    final scheme = Theme.of(context).colorScheme;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add, color: scheme.primary),
              title: const Text('Add to Today\'s Log'),
              onTap: () {
                Get.back();
                _addFavoriteToLog(meal);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite_border, color: scheme.error),
              title: const Text('Remove from Favorites'),
              onTap: () {
                Get.back();
                controller.removeFromFavorites(meal);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => LogMealActionSheet.show(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Log meal'),
    );
  }

  void _addFavoriteToLog(Map<String, dynamic> meal) {
    final mealToAdd = Map<String, dynamic>.from(meal);
    mealToAdd.addAll({
      'time':
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'notes': '',
      'favorite': true,
    });

    controller.addMeal(mealToAdd);

    CustomThemeFlushbar.show(
      title: 'Added',
      message: '${meal['name']} added from favorites',
    );
  }

  void _showSearchDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final TextEditingController searchController = TextEditingController();
    searchController.text = controller.searchQuery.value;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.search, color: scheme.primary),
            const SizedBox(width: 12),
            Text(
              'Search Meals',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by meal name...',
                prefixIcon: Icon(Icons.search, color: scheme.primary),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: scheme.outline,
                          ),
                          onPressed: () {
                            searchController.clear();
                            controller.clearSearch();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                controller.searchMeals(value);
              },
            ),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                '${controller.filteredMeals.length} meals found',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearSearch();
              Get.back();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMealOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Meal Options',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.cloud_sync, color: scheme.tertiary),
              title: const Text('Sync with Firebase'),
              onTap: () async {
                Get.back();
                await controller.loadDataFromFirebase();
                CustomThemeFlushbar.show(
                  title: 'Synced',
                  message: 'Data refreshed from Firebase',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.clear_all, color: scheme.error),
              title: const Text('Clear All Meals'),
              onTap: () {
                Get.back();
                _showClearAllConfirmation(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: scheme.primary),
              title: const Text('Export Data'),
              onTap: () {
                Get.back();
                controller.exportData();
              },
            ),
            ListTile(
              leading: Icon(Icons.upload, color: scheme.tertiary),
              title: const Text('Import Data'),
              onTap: () {
                Get.back();
                controller.importData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Meals'),
        content: const Text(
          'Are you sure you want to clear all meals for today? This will also remove them from Firebase and cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.clearAllMeals();
              Get.back();
              CustomThemeFlushbar.show(
                title: 'Cleared',
                message: 'All meals have been cleared',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More Options',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.settings, color: scheme.primary),
              title: const Text('Goals & Settings'),
              onTap: () {
                Get.back();
                _showGoalsDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: scheme.secondary),
              title: const Text('Detailed Nutrition'),
              onTap: () {
                Get.back();
                _showDetailedNutrition(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: scheme.tertiary),
              title: const Text('Weekly Report'),
              onTap: () {
                Get.back();
                _showWeeklyReport(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.sync, color: scheme.tertiary),
              title: const Text('Sync Data'),
              onTap: () {
                Get.back();
                controller.loadDataFromFirebase();
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: scheme.primary),
              title: const Text('Export Data'),
              onTap: () {
                Get.back();
                controller.exportData();
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: scheme.tertiary),
              title: const Text('About Nutri-Check'),
              onTap: () {
                Get.back();
                Get.dialog(
                  AlertDialog(
                    title: const Text('About Nutri-Check'),
                    content: const Text(
                      'This Nutrition Tracker helps you log and monitor your daily meals and nutritional intake. Data is synced with Firebase for backup and accessibility across devices. Stay healthy and informed!',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Get.back(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalsDialog(BuildContext context) {
    final calorieController = TextEditingController(
      text: controller.calorieGoal.value.toString(),
    );
    final proteinController = TextEditingController(
      text: controller.proteinGoal.value.toString(),
    );
    final carbController = TextEditingController(
      text: controller.carbGoal.value.toString(),
    );
    final fatController = TextEditingController(
      text: controller.fatGoal.value.toString(),
    );
    final waterController = TextEditingController(
      text: controller.waterGoal.value.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Set Daily Goals'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: calorieController,
                  decoration: const InputDecoration(
                    labelText: 'Calorie Goal (kcal)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Protein Goal (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: carbController,
                  decoration: const InputDecoration(
                    labelText: 'Carbs Goal (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  decoration: const InputDecoration(
                    labelText: 'Fat Goal (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: waterController,
                  decoration: const InputDecoration(
                    labelText: 'Water Goal (glasses)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.updateGoals(
                calories: double.tryParse(calorieController.text),
                proteins: double.tryParse(proteinController.text),
                carbs: double.tryParse(carbController.text),
                fats: double.tryParse(fatController.text),
                water: double.tryParse(waterController.text),
              );
              Get.back();
              CustomThemeFlushbar.show(
                title: 'Success',
                message: 'Your goals have been updated',
              );
            },
            child: const Text('Save Goals'),
          ),
        ],
      ),
    );
  }

  void _showDetailedNutrition(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Get.dialog(
      AlertDialog(
        title: const Text('Detailed Nutrition'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNutrientRow(
                  context,
                  'Calories',
                  '${controller.totalCalories.value.toInt()}',
                  'kcal',
                  scheme.primary,
                ),
                _buildNutrientRow(
                  context,
                  'Proteins',
                  '${controller.totalProteins.value.toInt()}',
                  'g',
                  scheme.primary,
                ),
                _buildNutrientRow(
                  context,
                  'Carbohydrates',
                  '${controller.totalCarbs.value.toInt()}',
                  'g',
                  scheme.tertiary,
                ),
                _buildNutrientRow(
                  context,
                  'Fats',
                  '${controller.totalFats.value.toInt()}',
                  'g',
                  scheme.secondary,
                ),
                const Divider(),
                Text(
                  'Data synced with NutriCheck!',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
    BuildContext context,
    String name,
    String value,
    String unit,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: textTheme.bodyMedium)),
          Text(
            '$value $unit',
            style: textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeeklyReport(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Get.dialog(
      AlertDialog(
        title: const Text('Weekly Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Weekly average: ${controller.weeklyCalories.reduce((a, b) => a + b) / controller.weeklyCalories.length ~/ 1} kcal/day',
              ),
              const SizedBox(height: 16),
              Text(
                'Advanced analytics coming soon.\nYour data is being tracked in Firebase.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _getMealTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Meals';
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snacks';
      case 'meal':
        return 'Meals';
      default:
        return type.capitalize!;
    }
  }
}
