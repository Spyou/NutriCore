import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:nutri_check/presentation/pages/ai_meal_analysis_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/nutrition_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPersonalizedHeader(context),
                Divider(),
                const SizedBox(height: 20),
                _buildDailyChallengeCard(context),
                const SizedBox(height: 20),
                _buildAIMealAnalysisCard(),
                const SizedBox(height: 20),
                _buildQuickActionHub(),
                const SizedBox(height: 20),
                _buildProgressRings(context),
                const SizedBox(height: 20),
                _buildWaterTracker(context),
                const SizedBox(height: 20),
                _buildActivityTimeline(context),
                const SizedBox(height: 20),
                _buildNutritionInsights(context),
                const SizedBox(height: 20),

                _buildWeeklyProgressChart(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIMealAnalysisCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: GestureDetector(
        onTap: () => Get.to(() => AIMealAnalysisPage()),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Meal Analysis',
                      style: AppTextStyles.headingSmall(Get.context!).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Snap a photo and get instant nutrition insights!',
                      style: AppTextStyles.bodySmall(
                        Get.context!,
                      ).copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizedHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.6),
            AppColors.tertiary.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getGreetingIcon(),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Good ${_getGreeting()}!',
                                  style: AppTextStyles.bodyLarge(context)
                                      .copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => Text(
                                'Hello ${controller.userName}! 👋',
                                style: AppTextStyles.headingLarge(context)
                                    .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile avatar with notification badge
                      GestureDetector(
                        onTap: () => _showAccountInfo(context),
                        child: Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Motivational quote
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track your nutrition journey today!',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(color: Colors.white.withOpacity(0.3)),
                      Text(
                        getMotivationalQuote(),
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getMotivationalQuote() {
    final quotes = [
      "Eat well, live well.",
      "Your body deserves the best.",
      "Healthy eating, happy living.",
      "Nourish to flourish.",
      "Small changes, big results.",
      "Fuel your body, fuel your life.",
      "Healthy habits, healthy you.",
      "Good food, good mood.",
      "Eat clean, stay lean.",
      "Wellness starts on your plate.",
    ];
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight;
  }

  Widget _buildProgressRings(BuildContext context) {
    final nutritionController = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Today\'s Progress',
            style: AppTextStyles.headingMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressRing(
                  'Calories',
                  nutritionController.totalCalories.value,
                  nutritionController.calorieGoal.value,
                  AppColors.calories,
                  Icons.local_fire_department,
                ),
                _buildProgressRing(
                  'Protein',
                  nutritionController.totalProteins.value,
                  nutritionController.proteinGoal.value,
                  AppColors.proteins,
                  Icons.fitness_center,
                ),
                _buildProgressRing(
                  'Water',
                  nutritionController.waterIntake.value,
                  nutritionController.waterGoal.value,
                  AppColors.info,
                  Icons.water_drop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(
    String label,
    double current,
    double goal,
    Color color,
    IconData icon,
  ) {
    final percent = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: CircularPercentIndicator(
        radius: 50.0,
        lineWidth: 8.0,
        percent: percent,
        animation: true,
        animationDuration: 1200,
        progressColor: color,
        backgroundColor: color.withOpacity(0.15),
        circularStrokeCap: CircularStrokeCap.round,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            Text(
              '${(percent * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium(
                  Get.context!,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${current.toInt()}/${goal.toInt()}',
                style: AppTextStyles.labelSmall(
                  Get.context!,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Action Hub with Smart Buttons
  Widget _buildQuickActionHub() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Quick Actions',
            style: AppTextStyles.headingMedium(
              Get.context!,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  subtitle: 'Product',
                  color: AppColors.primary,
                  onTap: () => Get.find<MainController>().changeIndex(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.restaurant_menu,
                  label: 'Add',
                  subtitle: 'Meal',
                  color: AppColors.secondary,
                  onTap: () => _showQuickAddMeal(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.water_drop,
                  label: 'Drink',
                  subtitle: 'Water',
                  color: AppColors.info,
                  onTap: () => _addWaterIntake(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge(
                Get.context!,
              ).copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall(
                Get.context!,
              ).copyWith(color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  // Daily Challenge
  Widget _buildDailyChallengeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.1),
            AppColors.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenge',
                      style: AppTextStyles.headingSmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      '🔥 ${_getCurrentStreak()} day streak!',
                      style: AppTextStyles.labelMedium(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getDailyChallenge(),
            style: AppTextStyles.bodyMedium(context).copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _getChallengeProgress(),
                  backgroundColor: AppColors.warning.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(_getChallengeProgress() * 100).toInt()}%',
                style: AppTextStyles.labelMedium(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Smart Water Tracker with Visual Feedback
  Widget _buildWaterTracker(BuildContext context) {
    final nutritionController = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Icon(Icons.water_drop, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              Text(
                'Water Intake',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Obx(
                () => Text(
                  '${nutritionController.waterIntake.value.toInt()}/${nutritionController.waterGoal.value.toInt()} glasses',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final glasses = nutritionController.waterIntake.value.toInt();
            final goal = nutritionController.waterGoal.value.toInt();

            return Row(
              children: List.generate(goal, (index) {
                final isFilled = index < glasses;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (index < glasses) {
                          nutritionController.removeWater();
                        } else {
                          nutritionController.addWater();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 40,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? AppColors.info
                              : AppColors.info.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: isFilled
                              ? Colors.white
                              : AppColors.info.withOpacity(0.5),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addWaterIntake(),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Glass'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💧 Stay hydrated!',
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Today's Activity Timeline
  Widget _buildActivityTimeline(BuildContext context) {
    final nutritionController = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Text(
                'Today\'s Activity',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.find<MainController>().changeIndex(3),
                child: Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final meals = nutritionController.todayMeals.take(3).toList();

            if (meals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        color: AppColors.textTertiary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No activity today',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start by adding your first meal!',
                        style: AppTextStyles.labelMedium(
                          context,
                        ).copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: meals.asMap().entries.map((entry) {
                final index = entry.key;
                final meal = entry.value;
                return _buildActivityItem(
                  meal,
                  index == meals.length - 1,
                  context,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    Map<String, dynamic> meal,
    bool isLast,
    BuildContext context,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getMealTypeColor(meal['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
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
                Text(
                  meal['name'] ?? 'Meal',
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${meal['calories']} kcal • ${meal['time'] ?? 'Unknown time'}',
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getMealTypeColor(meal['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meal['type']?.toString().capitalize ?? 'Meal',
              style: AppTextStyles.labelSmall(context).copyWith(
                color: _getMealTypeColor(meal['type']),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInsights(BuildContext context) {
    final nutritionController = Get.find<NutritionController>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Insights',
                style: AppTextStyles.headingMedium(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              _getSmartInsight(nutritionController),
              style: AppTextStyles.bodyMedium(context).copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getNutritionTip(),
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Text(
                'Weekly Progress',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+12% this week',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final height = (20 + Random().nextInt(40)).toDouble();
                final day = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                final isToday = index == DateTime.now().weekday - 1;

                return Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 30,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 30,
                            height: height,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day,
                      style: AppTextStyles.labelSmall(context).copyWith(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  int _getCurrentStreak() {
    return 5;
  }

  String _getDailyChallenge() {
    final challenges = [
      'Drink 8 glasses of water today! 💧',
      'Add protein to every meal today! 💪',
      'Take a 10-minute walk after eating! 🚶‍♂️',
      'Try a new healthy recipe! 👨‍🍳',
      'Eat 5 servings of vegetables! 🥗',
    ];
    return challenges[DateTime.now().day % challenges.length];
  }

  double _getChallengeProgress() {
    return 0.6;
  }

  String _getSmartInsight(NutritionController controller) {
    final calories = controller.totalCalories.value;
    final goal = controller.calorieGoal.value;

    if (calories < goal * 0.3) {
      return 'You\'re eating much less than usual today. Make sure to fuel your body properly! 🍽️';
    } else if (calories > goal * 1.2) {
      return 'You\'ve exceeded your calorie goal by ${((calories - goal) / goal * 100).toInt()}%. Consider lighter meals tomorrow. ⚖️';
    } else {
      return 'Great job staying on track! You\'re ${((calories / goal) * 100).toInt()}% toward your daily goal. 🎯';
    }
  }

  String _getNutritionTip() {
    final tips = [
      'Protein helps you feel full longer - aim for some in every meal!',
      'Drinking water before meals can help with portion control.',
      'Colorful plates usually mean more nutrients!',
      'Eating slowly helps your brain register when you\'re full.',
      'Fiber keeps you satisfied and aids digestion.',
    ];
    return tips[DateTime.now().day % tips.length];
  }

  void _showQuickAddMeal() {
    // Implement quick add meal functionality
    HapticFeedback.mediumImpact();
    Get.find<MainController>().changeIndex(3);
  }

  void _addWaterIntake() {
    final nutritionController = Get.find<NutritionController>();
    nutritionController.addWater();
    HapticFeedback.lightImpact();

    CustomThemeFlushbar(title: '💧 Great!', message: 'Added 1 glass of water');
  }

  void _showAccountInfo(BuildContext context) {
    final authController = Get.find<AuthController>();
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
            Text('Account Info', style: AppTextStyles.headingMedium(context)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text(authController.user?.email ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Name'),
              subtitle: Text(authController.user?.displayName ?? 'Not set'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  authController.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
