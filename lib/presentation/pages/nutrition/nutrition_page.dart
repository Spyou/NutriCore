import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/nutrition_controller.dart';

class NutritionPage extends GetView<NutritionController> {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.manualRefresh();
        },
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewModeToggle(),
                    const SizedBox(height: 20),
                    _buildStatsOverview(controller),
                    const SizedBox(height: 20),
                    _buildCalorieProgress(),
                    const SizedBox(height: 20),
                    _buildMacroBreakdown(),
                    const SizedBox(height: 20),
                    _buildWaterTracking(),
                    const SizedBox(height: 20),
                    _buildMealFilters(),
                    const SizedBox(height: 12),
                    _buildMealsList(),
                    const SizedBox(height: 20),
                    // _buildQuickActions(),
                    // const SizedBox(height: 20),
                    _buildFavoriteMeals(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSliverAppBar() {
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
                colors: AppColors.primaryGradient,
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
                duration: Duration(milliseconds: 200),
                child: shrinkPercentage > 0.5
                    ? Text(
                        'Nutrition',
                        key: ValueKey('collapsed'),
                        style: AppTextStyles.headingMedium(Get.context!)
                            .copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      )
                    : null,
              ),
              background: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 80, // More space for actions
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Only show when expanded
                      if (shrinkPercentage < 0.5) ...[
                        Text(
                          'Nutrition Tracker',
                          style: AppTextStyles.displayMedium(Get.context!)
                              .copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                              ),
                        ),
                        SizedBox(height: 4),
                        // Constrained row for date navigation
                        SizedBox(
                          width:
                              MediaQuery.of(context).size.width -
                              120, // Constrain width
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Obx(
                                  () => Text(
                                    _formatDate(controller.selectedDate.value),
                                    style: AppTextStyles.bodyLarge(Get.context!)
                                        .copyWith(
                                          color: AppColors.textOnPrimary
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              _buildDateNavigation(),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
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
        // Loading indicator
        Obx(
          () => controller.isLoading.value
              ? Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),

        // More options button
        IconButton(
          onPressed: _showMoreOptions,
          icon: Icon(Icons.more_vert, color: AppColors.textOnPrimary),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }

  Widget _buildDateNavigation() {
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.chevron_left,
                color: AppColors.textOnPrimary,
                size: 16,
              ),
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.textOnPrimary,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: ['daily', 'weekly', 'monthly'].map((mode) {
            final isSelected = controller.viewMode.value == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  // 🔥 FIXED: Proper view mode change
                  HapticFeedback.lightImpact();
                  controller.changeViewMode(mode);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    mode.capitalize!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge(Get.context!).copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
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

  Widget _buildStatsOverview(NutritionController controller) {
    return Obx(() {
      final stats = controller.currentStats;
      final viewMode = controller.viewMode.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with period info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${viewMode.capitalize!} Overview',
                  style: AppTextStyles.headingMedium(Get.context!),
                ),
                if (controller.isLoadingViewData.value)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Period info
            Text(
              _getPeriodText(viewMode, stats),
              style: AppTextStyles.bodySmall(
                Get.context!,
              ).copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Calories',
                    '${(stats['totalCalories'] ?? 0).toInt()}',
                    Icons.local_fire_department,
                    AppColors.calories,
                    subtitle: viewMode != 'daily'
                        ? 'Avg: ${(stats['averageCalories'] ?? 0).toInt()}/day'
                        : null,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.textTertiary.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Meals',
                    '${stats['totalMeals'] ?? 0}',
                    Icons.restaurant,
                    AppColors.secondary,
                    subtitle: viewMode != 'daily'
                        ? '${stats['daysWithData'] ?? 0} days'
                        : null,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.textTertiary.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Weight',
                    '${controller.userWeight.value.toInt()} kg',
                    Icons.monitor_weight,
                    AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _getPeriodText(String viewMode, Map<String, dynamic> stats) {
    switch (viewMode) {
      case 'daily':
        return 'Today • ${stats['date'] ?? ''}';
      case 'weekly':
        return 'This Week • ${stats['startDate']} to ${stats['endDate']}';
      case 'monthly':
        return '${stats['monthName']} • ${stats['daysWithData']}/${stats['totalDays']} days logged';
      default:
        return '';
    }
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headingSmall(
            Get.context!,
          ).copyWith(color: color),
        ),
        Text(label, style: AppTextStyles.labelMedium(Get.context!)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.labelSmall(
              Get.context!,
            ).copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }

  Widget _buildCalorieProgress() {
    return Obx(() {
      final progress =
          controller.totalCalories.value / controller.calorieGoal.value;
      final remaining =
          controller.calorieGoal.value - controller.totalCalories.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.calories.withOpacity(0.1),
              AppColors.calories.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.calories.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.calories,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${controller.totalCalories.value.toInt()} kcal',
                        style: AppTextStyles.headingLarge(
                          Get.context!,
                        ).copyWith(color: AppColors.calories),
                      ),
                      Text(
                        remaining > 0
                            ? '${remaining.toInt()} kcal remaining'
                            : '${(-remaining).toInt()} kcal over',
                        style: AppTextStyles.bodyMedium(Get.context!).copyWith(
                          color: remaining > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.headingSmall(Get.context!).copyWith(
                    color: AppColors.calories,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 1.0 ? AppColors.error : AppColors.calories,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMacroBreakdown() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Macronutrients',
                  style: AppTextStyles.headingMedium(Get.context!),
                ),
                IconButton(
                  onPressed: _showDetailedNutrition,
                  icon: const Icon(Icons.info_outline, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroCircle(
                  'Proteins',
                  controller.totalProteins.value,
                  controller.proteinGoal.value,
                  AppColors.proteins,
                ),
                _buildMacroCircle(
                  'Carbs',
                  controller.totalCarbs.value,
                  controller.carbGoal.value,
                  AppColors.carbs,
                ),
                _buildMacroCircle(
                  'Fats',
                  controller.totalFats.value,
                  controller.fatGoal.value,
                  AppColors.fats,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCircle(
    String label,
    double current,
    double goal,
    Color color,
  ) {
    final progress = current / goal;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyles.labelMedium(
                Get.context!,
              ).copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.labelMedium(Get.context!)),
        Text(
          '${current.toInt()}/${goal.toInt()}g',
          style: AppTextStyles.labelSmall(Get.context!).copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildWaterTracking() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Water Intake',
                  style: AppTextStyles.headingMedium(Get.context!),
                ),
                Text(
                  '${controller.waterIntake.value.toInt()}/${controller.waterGoal.value.toInt()} glasses',
                  style: AppTextStyles.bodyMedium(Get.context!).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value:
                        (controller.waterIntake.value /
                                controller.waterGoal.value)
                            .clamp(0.0, 1.0),
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.removeWater,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.error,
                      iconSize: 28,
                    ),
                    IconButton(
                      onPressed: controller.addWater,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
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

  Widget _buildMealFilters() {
    final mealTypes = ['all', 'breakfast', 'lunch', 'dinner', 'snack'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Meals',
              style: AppTextStyles.headingMedium(Get.context!),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _showSearchDialog,
                  icon: const Icon(Icons.search, size: 20),
                ),
                IconButton(
                  onPressed: _showMealOptions,
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
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: controller.selectedMealType.value == type
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
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

  Widget _buildMealsList() {
    return Obx(() {
      final meals = controller.filteredMeals;

      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (meals.isEmpty) {
        return _buildEmptyMealsState();
      }

      return Column(
        children: meals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;
          return _buildMealCard(
            meal,
            index,
            controller.viewMode.value,
            controller,
          );
        }).toList(),
      );
    });
  }

  Widget _buildEmptyMealsState() {
    return Obx(() {
      String message;
      String subtitle;
      IconData icon;

      if (controller.searchQuery.value.isNotEmpty) {
        message = 'No meals found';
        subtitle = 'No meals match "${controller.searchQuery.value}"';
        icon = Icons.search_off;
      } else if (controller.selectedMealType.value != 'all') {
        message = 'No ${controller.selectedMealType.value} meals';
        subtitle = 'Try adding a ${controller.selectedMealType.value} meal';
        icon = Icons.restaurant_outlined;
      } else {
        message = 'No meals logged today';
        subtitle = 'Add your first meal to start tracking';
        icon = Icons.add_circle_outline;
      }

      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(icon, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.headingSmall(
                  Get.context!,
                ).copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium(
                  Get.context!,
                ).copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              if (controller.searchQuery.value.isNotEmpty ||
                  controller.selectedMealType.value != 'all') ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => controller.resetFilters(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // Add this method to your NutritionPage class
  String _getMealPeriodContext(Map<String, dynamic> meal, String viewMode) {
    if (viewMode == 'weekly') {
      return meal['day'] ?? meal['date'] ?? '';
    } else if (viewMode == 'monthly') {
      final date = meal['date'] ?? '';
      final week = meal['week'] ?? 1;
      return '$date (Week $week)';
    }
    return '';
  }

  Widget _buildMealCard(
    Map<String, dynamic> meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    // Only allow sliding in daily view
    if (viewMode != 'daily') {
      return _buildStaticMealCard(meal, index, viewMode, controller);
    }

    // Slidable meal card with delete action
    return Slidable(
      key: ValueKey(meal['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // Edit action
          SlidableAction(
            onPressed: (context) => _editMeal(index, meal, controller),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),

          // Duplicate action
          SlidableAction(
            onPressed: (context) => controller.duplicateMeal(index),
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            icon: Icons.copy,
            label: 'Copy',
          ),

          // 🔥 DELETE ACTION with confirmation
          SlidableAction(
            onPressed: (context) async {
              // Use the confirmation dialog
              final confirmed = await _showDeleteConfirmation(meal['name']);
              if (confirmed) {
                controller.deleteMeal(index);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${meal['name']} deleted'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(label: 'Undo', onPressed: () {}),
                  ),
                );
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
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
            onPressed: (context) => controller.toggleFavorite(meal),
            backgroundColor: controller.isFavorite(meal)
                ? Colors.grey
                : AppColors.warning,
            foregroundColor: Colors.white,
            icon: controller.isFavorite(meal)
                ? Icons.favorite
                : Icons.favorite_border,
            label: controller.isFavorite(meal) ? 'Unfav' : 'Fav',
          ),
        ],
      ),

      // Meal card content
      child: _buildMealCardContent(meal, index, viewMode, controller),
    );
  }

  Widget _buildStaticMealCard(
    Map<String, dynamic> meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    return _buildMealCardContent(meal, index, viewMode, controller);
  }

  Widget _buildMealCardContent(
    Map<String, dynamic> meal,
    int index,
    String viewMode,
    NutritionController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.isFavorite(meal)
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getMealTypeColor(meal['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMealIcon(meal['type']),
                  color: _getMealTypeColor(meal['type']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal['name'] ?? 'Unknown Meal',
                            style: AppTextStyles.bodyLarge(
                              Get.context!,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (controller.isFavorite(meal))
                          Icon(
                            Icons.favorite,
                            color: AppColors.warning,
                            size: 16,
                          ),
                      ],
                    ),
                    Text(
                      '${meal['calories'] ?? 0} kcal • P: ${meal['proteins'] ?? 0}g • C: ${meal['carbs'] ?? 0}g • F: ${meal['fat'] ?? 0}g',
                      style: AppTextStyles.bodySmall(
                        Get.context!,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    // Show period context for weekly/monthly views
                    if (viewMode != 'daily') ...[
                      const SizedBox(height: 4),
                      Text(
                        _getMealPeriodContext(meal, viewMode),
                        style: AppTextStyles.labelSmall(Get.context!).copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
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
                    meal['time'] ?? '',
                    style: AppTextStyles.labelMedium(
                      Get.context!,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  if (viewMode == 'daily')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.swipe,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String mealName) async {
    return await showDialog<bool>(
          context: Get.context!,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Delete Meal',
                    style: AppTextStyles.headingMedium(
                      Get.context!,
                    ).copyWith(color: Colors.red),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete this meal?',
                    style: AppTextStyles.bodyMedium(Get.context!),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mealName,
                            style: AppTextStyles.bodyMedium(Get.context!)
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This action cannot be undone.',
                    style: AppTextStyles.bodySmall(Get.context!).copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, size: 18),
                      SizedBox(width: 4),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  Color _getMealTypeColor(String? type) {
    switch (type) {
      case 'breakfast':
        return AppColors.warning;
      case 'lunch':
        return AppColors.success;
      case 'dinner':
        return AppColors.info;
      case 'snack':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getMealIcon(String? type) {
    switch (type) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nights_stay;
      case 'snack':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }

  // Widget _buildQuickActions() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text('Quick Actions', style: AppTextStyles.headingMedium(Get.context!)),
  //       const SizedBox(height: 12),
  //       GridView.count(
  //         shrinkWrap: true,
  //         padding: EdgeInsets.zero,
  //         physics: const NeverScrollableScrollPhysics(),
  //         crossAxisCount: 2,
  //         childAspectRatio: 2.5,
  //         crossAxisSpacing: 12,
  //         mainAxisSpacing: 12,
  //         children: [
  //           _buildQuickActionCard(
  //             '🔄 Manual Sync',
  //             Icons.refresh,
  //             AppColors.info,
  //             () async {
  //               await controller.manualRefresh();
  //               Get.snackbar(
  //                 '🔄 Refreshed',
  //                 'Data refreshed from Firebase',
  //                 snackPosition: SnackPosition.BOTTOM,
  //                 backgroundColor: AppColors.success,
  //                 colorText: Colors.white,
  //               );
  //             },
  //           ),
  //           _buildQuickActionCard(
  //             'Scan Food',
  //             Icons.qr_code_scanner,
  //             AppColors.primary,
  //             () => Get.find<MainController>().changeIndex(2),
  //           ),
  //           _buildQuickActionCard(
  //             '💾 Sync Data',
  //             Icons.cloud_sync,
  //             AppColors.info,
  //             () async {
  //               await controller.loadDataFromFirebase();
  //               Get.snackbar(
  //                 '☁️ Synced',
  //                 'Data synced with Firebase successfully',
  //                 snackPosition: SnackPosition.BOTTOM,
  //                 backgroundColor: AppColors.success,
  //                 colorText: Colors.white,
  //               );
  //             },
  //           ),
  //           _buildQuickActionCard(
  //             'Water +1',
  //             Icons.water_drop,
  //             AppColors.info,
  //             controller.addWater,
  //           ),
  //           _buildQuickActionCard(
  //             'Export Data',
  //             Icons.download,
  //             AppColors.success,
  //             controller.exportData,
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildQuickActionCard(
  //   String label,
  //   IconData icon,
  //   Color color,
  //   VoidCallback onTap,
  // ) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //       decoration: BoxDecoration(
  //         color: color.withOpacity(0.1),
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(color: color.withOpacity(0.3)),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, color: color, size: 24),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Text(
  //               label,
  //               style: AppTextStyles.labelLarge(
  //                 Get.context!,
  //               ).copyWith(color: color, fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFavoriteMeals() {
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
                style: AppTextStyles.headingMedium(Get.context!),
              ),
              IconButton(
                onPressed: () => controller.clearAllFavorites(),
                icon: Icon(Icons.clear_all, color: Colors.grey[600]),
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
              itemBuilder: (context, index) {
                final meal = controller.favoriteMeals[index];
                return _buildFavoriteMealCard(meal);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFavoriteMealCard(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () => _addFavoriteToLog(meal),
      onLongPress: () => _showFavoriteMealOptions(meal),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: AppColors.warning, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meal['name'],
                    style: AppTextStyles.labelLarge(
                      Get.context!,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => controller.removeFromFavorites(meal),
                  child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${meal['calories']} kcal',
              style: AppTextStyles.bodySmall(
                Get.context!,
              ).copyWith(color: AppColors.textSecondary),
            ),
            Text(
              'P: ${meal['proteins']}g • C: ${meal['carbs']}g',
              style: AppTextStyles.labelSmall(
                Get.context!,
              ).copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoriteMealOptions(Map<String, dynamic> meal) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add, color: AppColors.primary),
              title: Text('Add to Today\'s Log'),
              onTap: () {
                Get.back();
                _addFavoriteToLog(meal);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite_border, color: Colors.red),
              title: Text('Remove from Favorites'),
              onTap: () {
                Get.back();
                controller.removeFromFavorites(meal);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: _showAddMealDialog,
          backgroundColor: AppColors.primary,
          heroTag: "add_meal",
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.small(
          onPressed: _showQuickAddDialog,
          backgroundColor: AppColors.secondary,
          heroTag: "quick_add",
          child: const Icon(Icons.flash_on, color: Colors.white),
        ),
      ],
    );
  }

  // Dialog Methods
  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinsController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'meal';

    Get.dialog(
      AlertDialog(
        title: const Text('Add Meal'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['breakfast', 'lunch', 'dinner', 'snack', 'meal']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getMealTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => selectedType = value ?? 'meal',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: proteinsController,
                        decoration: const InputDecoration(
                          labelText: 'Proteins (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbsController,
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: fatsController,
                        decoration: const InputDecoration(
                          labelText: 'Fats (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories = double.tryParse(caloriesController.text) ?? 0;
              final proteins = double.tryParse(proteinsController.text) ?? 0;
              final carbs = double.tryParse(carbsController.text) ?? 0;
              final fats = double.tryParse(fatsController.text) ?? 0;

              if (name.isNotEmpty && calories > 0) {
                controller.addMeal({
                  'name': name,
                  'calories': calories,
                  'proteins': proteins,
                  'carbs': carbs,
                  'fat': fats,
                  'fiber': 0.0,
                  'sugar': 0.0,
                  'sodium': 0.0,
                  'type': selectedType,
                  'time':
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  'image': null,
                  'notes': notesController.text.trim(),
                  'favorite': false,
                });
                Get.back();
                HapticFeedback.lightImpact();
                Get.snackbar(
                  '🎉 Success',
                  'Meal added and synced to Firebase!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter meal name and calories',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Meal'),
          ),
        ],
      ),
    );
  }

  void _editMeal(
    int index,
    Map<String, dynamic> meal,
    NutritionController controller,
  ) {
    final nameController = TextEditingController(text: meal['name']);
    final caloriesController = TextEditingController(
      text: meal['calories'].toString(),
    );
    final proteinsController = TextEditingController(
      text: meal['proteins'].toString(),
    );
    final carbsController = TextEditingController(
      text: meal['carbs'].toString(),
    );
    final fatsController = TextEditingController(text: meal['fat'].toString());
    final notesController = TextEditingController(text: meal['notes'] ?? '');
    String selectedType = meal['type'] ?? 'meal';

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Meal'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['breakfast', 'lunch', 'dinner', 'snack', 'meal']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getMealTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => selectedType = value ?? 'meal',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: proteinsController,
                        decoration: const InputDecoration(
                          labelText: 'Proteins (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbsController,
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: fatsController,
                        decoration: const InputDecoration(
                          labelText: 'Fats (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories = double.tryParse(caloriesController.text) ?? 0;
              final proteins = double.tryParse(proteinsController.text) ?? 0;
              final carbs = double.tryParse(carbsController.text) ?? 0;
              final fats = double.tryParse(fatsController.text) ?? 0;

              if (name.isNotEmpty && calories > 0) {
                final updatedMeal = Map<String, dynamic>.from(meal);
                updatedMeal.addAll({
                  'name': name,
                  'calories': calories,
                  'proteins': proteins,
                  'carbs': carbs,
                  'fat': fats,
                  'type': selectedType,
                  'notes': notesController.text.trim(),
                });

                controller.editMeal(index, updatedMeal);
                Get.back();
                Get.snackbar(
                  '✅ Success',
                  'Meal updated and synced to Firebase!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog() {
    final quickItems = [
      {
        'name': 'Apple',
        'calories': 95,
        'proteins': 0.5,
        'carbs': 25.0,
        'fat': 0.3,
      },
      {
        'name': 'Banana',
        'calories': 105,
        'proteins': 1.3,
        'carbs': 27.0,
        'fat': 0.4,
      },
      {
        'name': 'Greek Yogurt',
        'calories': 100,
        'proteins': 17.0,
        'carbs': 9.0,
        'fat': 0.4,
      },
      {
        'name': 'Protein Shake',
        'calories': 200,
        'proteins': 25.0,
        'carbs': 5.0,
        'fat': 3.0,
      },
      {
        'name': 'Chicken Breast (100g)',
        'calories': 165,
        'proteins': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
      },
      {
        'name': 'Brown Rice (1 cup)',
        'calories': 216,
        'proteins': 5.0,
        'carbs': 45.0,
        'fat': 1.8,
      },
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Text('Quick Add', style: AppTextStyles.headingMedium(Get.context!)),
            const SizedBox(height: 16),
            ...quickItems.map(
              (item) => ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                title: Text(item['name'] as String),
                subtitle: Text('${item['calories']} kcal'),
                onTap: () {
                  controller.addQuickMeal(item['name'] as String, item);
                  Get.back();
                  Get.snackbar(
                    '🎉 Added',
                    '${item['name']} added to your log and synced!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

    CustomThemeFlushbar(
      title: '❤️ Added',
      message: '${meal['name']} added from favorites and synced!',
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    searchController.text = controller.searchQuery.value;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.search, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'Search Meals',
              style: AppTextStyles.headingSmall(Get.context!),
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
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.outline),
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
                style: AppTextStyles.bodySmall(
                  Get.context!,
                ).copyWith(color: AppColors.textSecondary),
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
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMealOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Meal Options',
              style: AppTextStyles.headingMedium(Get.context!),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.cloud_sync, color: AppColors.info),
              title: const Text('Sync with Firebase'),
              onTap: () async {
                Get.back();
                await controller.loadDataFromFirebase();
                Get.snackbar(
                  '☁️ Synced',
                  'Data refreshed from Firebase',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.clear_all, color: AppColors.error),
              title: const Text('Clear All Meals'),
              onTap: () {
                Get.back();
                _showClearAllConfirmation();
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: AppColors.success),
              title: const Text('Export Data'),
              onTap: () {
                Get.back();
                controller.exportData();
              },
            ),
            ListTile(
              leading: Icon(Icons.upload, color: AppColors.info),
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

  void _showClearAllConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Meals'),
        content: const Text(
          'Are you sure you want to clear all meals for today? This will also remove them from Firebase and cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.clearAllMeals();
              Get.back();
              CustomThemeFlushbar(
                title: 'Cleared',
                message: 'All meals have been cleared and synced to Firebase',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More Options',
              style: AppTextStyles.headingMedium(Get.context!),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.settings, color: AppColors.primary),
              title: const Text('Goals & Settings'),
              onTap: () {
                Get.back();
                _showGoalsDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: AppColors.secondary),
              title: const Text('Detailed Nutrition'),
              onTap: () {
                Get.back();
                _showDetailedNutrition();
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: AppColors.info),
              title: const Text('Weekly Report'),
              onTap: () {
                Get.back();
                _showWeeklyReport();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.sync, color: AppColors.info),
              title: const Text('Sync Data'),
              onTap: () {
                Get.back();
                controller.loadDataFromFirebase();
              },
            ),

            ListTile(
              leading: Icon(Icons.download, color: AppColors.success),
              title: const Text('Export Data'),
              onTap: () {
                Get.back();
                controller.exportData();
              },
            ),

            ListTile(
              leading: Icon(Icons.info, color: AppColors.tertiary),
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
                      ElevatedButton(
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

  void _showGoalsDialog() {
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
          ElevatedButton(
            onPressed: () {
              controller.updateGoals(
                calories: double.tryParse(calorieController.text),
                proteins: double.tryParse(proteinController.text),
                carbs: double.tryParse(carbController.text),
                fats: double.tryParse(fatController.text),
                water: double.tryParse(waterController.text),
              );
              Get.back();
              Get.snackbar(
                'Success',
                'Your goals have been updated and synced!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.success,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Goals'),
          ),
        ],
      ),
    );
  }

  void _showDetailedNutrition() {
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
                  'Calories',
                  '${controller.totalCalories.value.toInt()}',
                  'kcal',
                  AppColors.calories,
                ),
                _buildNutrientRow(
                  'Proteins',
                  '${controller.totalProteins.value.toInt()}',
                  'g',
                  AppColors.proteins,
                ),
                _buildNutrientRow(
                  'Carbohydrates',
                  '${controller.totalCarbs.value.toInt()}',
                  'g',
                  AppColors.carbs,
                ),
                _buildNutrientRow(
                  'Fats',
                  '${controller.totalFats.value.toInt()}',
                  'g',
                  AppColors.fats,
                ),
                const Divider(),
                Text(
                  'Data synced with NutriCheck!',
                  style: AppTextStyles.bodySmall(
                    Get.context!,
                  ).copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
    String name,
    String value,
    String unit,
    Color color,
  ) {
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
          Expanded(
            child: Text(name, style: AppTextStyles.bodyMedium(Get.context!)),
          ),
          Text(
            '$value $unit',
            style: AppTextStyles.bodyMedium(
              Get.context!,
            ).copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showWeeklyReport() {
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
                'Advanced analytics coming soon! 📊\nYour data is being tracked in Firebase.',
                style: AppTextStyles.bodyMedium(
                  Get.context!,
                ).copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  // Helper Methods
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
    } else if (targetDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else if (targetDate == today.add(Duration(days: 1))) {
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
