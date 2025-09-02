import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/services/theme_service.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';
import 'package:nutri_check/presentation/pages/profile/about_me.dart';
import 'package:nutri_check/presentation/pages/theme_settings_page.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: () async {
            final nutritionController = Get.find<NutritionController>();
            final profileController = Get.find<ProfileController>();

            await nutritionController.refreshData();
            await profileController.refreshStats();
          },
          child: Obx(
            () => controller.isLoading.value
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(controller),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _buildProfileHeader(controller),
                            _buildStatsCards(controller),
                            _buildHealthMetrics(controller),
                            _buildSettingsSection(controller),
                            _developerInfo(),
                            SizedBox(height: 20), // Bottom padding
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ProfileController controller) {
    return SliverAppBar(
      expandedHeight: 120,
      toolbarHeight: 44,
      floating: true,
      pinned: true,
      snap: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double top = constraints.biggest.height;
          final double collapsedHeight =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          final double expandedHeight =
              120 + MediaQuery.of(context).padding.top;
          final double shrinkOffset = expandedHeight - top;
          final double shrinkPercentage =
              (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(
                0.0,
                1.0,
              );

          return AnimatedContainer(
            duration: Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(
                    0.95 + (0.05 * shrinkPercentage),
                  ),
                  AppColors.tertiary.withOpacity(
                    0.85 + (0.15 * shrinkPercentage),
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12.0 * (1 - shrinkPercentage),
                  sigmaY: 12.0 * (1 - shrinkPercentage),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                          ? Obx(
                              () => Text(
                                controller.userName.value.isNotEmpty
                                    ? controller.userName.value
                                    : 'Profile',
                                key: ValueKey('collapsed_profile'),
                                style: AppTextStyles.headingMedium(Get.context!)
                                    .copyWith(
                                      color: AppColors.textOnPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 28 - (6 * shrinkPercentage),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : null,
                    ),
                    background: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, right: 60, top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                // Profile image with animation

                                // Profile info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Profile title
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          15 * shrinkPercentage,
                                        ),
                                        child: Opacity(
                                          opacity: (1 - shrinkPercentage * 1.5)
                                              .clamp(0.0, 1.0),
                                          child: Text(
                                            'Profile',
                                            style:
                                                AppTextStyles.bodySmall(
                                                  Get.context!,
                                                ).copyWith(
                                                  color:
                                                      AppColors.textOnPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      28 -
                                                      (6 * shrinkPercentage),
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      // Member since text
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          10 * shrinkPercentage,
                                        ),
                                        child: Opacity(
                                          opacity: (1 - shrinkPercentage * 1.2)
                                              .clamp(0.0, 1.0),
                                          child: Obx(
                                            () => Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Member',
                                                    style:
                                                        AppTextStyles.labelSmall(
                                                          Get.context!,
                                                        ).copyWith(
                                                          color: AppColors
                                                              .textOnPrimary,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'since ${_formatDate(controller.joinDate.value)}',
                                                  style:
                                                      AppTextStyles.bodyMedium(
                                                        Get.context!,
                                                      ).copyWith(
                                                        color: AppColors
                                                            .textOnPrimary
                                                            .withOpacity(0.9),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        // Edit profile button
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                HapticFeedback.lightImpact();
                _showEditProfileDialog(controller);
              },
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              Obx(
                () => CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: controller.profileImageUrl.value.isNotEmpty
                      ? NetworkImage(controller.profileImageUrl.value)
                      : null,
                  child: controller.profileImageUrl.value.isEmpty
                      ? Icon(Icons.person, size: 60, color: AppColors.primary)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: controller.updateProfileImage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Obx(
                      () => controller.isUploadingImage.value
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Name and Email
          Obx(
            () => Text(
              controller.userName.value,
              style: AppTextStyles.headingLarge(
                Get.context!,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 4),
          Obx(
            () => Text(
              controller.userEmail.value,
              style: AppTextStyles.bodyMedium(
                Get.context!,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 8),

          // Bio
          Obx(
            () => controller.userBio.value.isNotEmpty
                ? Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.userBio.value,
                      style: AppTextStyles.bodyMedium(Get.context!),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ProfileController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _buildStatCard(
                'Meals Logged',
                controller.totalMealsLogged.value.toString(),
                Icons.restaurant,
                AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => _buildStatCard(
                'Total Calories',
                controller
                    .formattedTotalCalories, // 🔥 FIXED: Use formatted getter
                Icons.local_fire_department,
                AppColors.calories,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => _buildStatCard(
                'Streak Days',
                controller.streakDays.value.toString(),
                Icons.flash_on,
                AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated icon with color transition
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1200),
                  builder: (context, iconValue, child) {
                    return Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1 * iconValue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Color.lerp(Colors.grey, color, iconValue),
                        size: 24,
                      ),
                    );
                  },
                ),
                SizedBox(height: 12),

                // Animated counter
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0.0,
                    end:
                        double.tryParse(
                          value.replaceAll(RegExp(r'[^0-9.]'), ''),
                        ) ??
                        0.0,
                  ),
                  duration: Duration(milliseconds: 1500),
                  builder: (context, counterValue, child) {
                    String displayValue;
                    if (value.contains('k')) {
                      displayValue =
                          '${(counterValue / 1000).toStringAsFixed(1)}k';
                    } else {
                      displayValue = counterValue.toInt().toString();
                    }

                    return Text(
                      displayValue,
                      style: AppTextStyles.headingSmall(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  },
                ),
                SizedBox(height: 4),

                // Title
                Text(
                  title,
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthMetrics(ProfileController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Metrics',
            style: AppTextStyles.headingMedium(Get.context!),
          ),
          SizedBox(height: 16),

          // Weight Progress
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem(
                  'Current Weight',
                  '${controller.currentWeight.value.toInt()} kg',
                  AppColors.info,
                ),
                _buildMetricItem(
                  'Target Weight',
                  '${controller.targetWeight.value.toInt()} kg',
                  AppColors.success,
                ),
                _buildMetricItem(
                  'To Goal',
                  '${(controller.currentWeight.value - controller.targetWeight.value).abs().toInt()} kg',
                  AppColors.warning,
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // BMI Section
          Obx(
            () => Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.bmiColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: controller.bmiColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monitor_weight,
                    color: controller.bmiColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI: ${controller.bmi.toStringAsFixed(1)}',
                          style: AppTextStyles.bodyLarge(Get.context!).copyWith(
                            fontWeight: FontWeight.w600,
                            color: controller.bmiColor,
                          ),
                        ),
                        Text(
                          controller.bmiCategory,
                          style: AppTextStyles.bodyMedium(
                            Get.context!,
                          ).copyWith(color: controller.bmiColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headingSmall(
            Get.context!,
          ).copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.labelMedium(
            Get.context!,
          ).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ProfileController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.headingMedium(Get.context!)),
          SizedBox(height: 16),

          // Notifications
          Obx(
            () => SwitchListTile(
              title: Text('Push Notifications'),
              subtitle: Text('Receive meal reminders and updates'),
              value: controller.notificationsEnabled.value,
              onChanged: (value) =>
                  controller.updateSettings(notifications: value),
              activeColor: AppColors.primary,
            ),
          ),

          // Weekly Reports
          Obx(
            () => SwitchListTile(
              title: Text('Weekly Reports'),
              subtitle: Text('Get weekly nutrition summaries'),
              value: controller.weeklyReportsEnabled.value,
              onChanged: (value) =>
                  controller.updateSettings(weeklyReports: value),
              activeColor: AppColors.primary,
            ),
          ),

          SizedBox(height: 16),

          _buildThemeSection(),

          Divider(),

          // Account Actions
          ListTile(
            leading: Icon(Icons.edit, color: AppColors.primary),
            title: Text('Edit Profile'),
            onTap: () => _showEditProfileDialog(controller),
          ),

          ListTile(
            leading: Icon(Icons.file_download, color: AppColors.primary),
            title: Text('Export Profile'),
            onTap: () => controller.exportUserData(),
          ),

          ListTile(
            leading: Icon(Icons.logout, color: AppColors.warning),
            title: Text('Sign Out'),
            onTap: controller.signOut,
          ),

          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.error),
            title: Text('Delete Account'),
            onTap: controller.deleteAccount,
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _developerInfo() {
    // Developer info section
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Text(
            'Developer',
            style: AppTextStyles.headingMedium(Get.context!),
          ),
        ),
        DeveloperAndDonationSection(),
      ],
    );
  }

  // In your profile page's edit profile dialog:
  void _showEditProfileDialog(ProfileController controller) {
    final nameController = TextEditingController(
      text: controller.userName.value,
    );
    final bioController = TextEditingController(text: controller.userBio.value);
    final weightController = TextEditingController(
      text: controller.currentWeight.value.toString(),
    );
    final targetController = TextEditingController(
      text: controller.targetWeight.value.toString(),
    );
    final heightController = TextEditingController(
      text: controller.height.value.toString(),
    );
    final ageController = TextEditingController(
      text: controller.age.value.toString(),
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: targetController,
                        decoration: InputDecoration(
                          labelText: 'Target (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      // 🔥 SAFE INPUT VALIDATION
                      final name = nameController.text.trim();
                      final bio = bioController.text.trim();
                      final weightText = weightController.text.trim();
                      final targetText = targetController.text.trim();
                      final heightText = heightController.text.trim();
                      final ageText = ageController.text.trim();

                      // Validate inputs
                      double? weight;
                      double? target;
                      double? height;
                      int? age;

                      try {
                        if (weightText.isNotEmpty) {
                          weight = double.parse(weightText);
                          if (weight <= 0 || weight > 500) {
                            throw Exception('Invalid weight range');
                          }
                        }

                        if (targetText.isNotEmpty) {
                          target = double.parse(targetText);
                          if (target <= 0 || target > 500) {
                            throw Exception('Invalid target weight range');
                          }
                        }

                        if (heightText.isNotEmpty) {
                          height = double.parse(heightText);
                          if (height <= 0 || height > 300) {
                            throw Exception('Invalid height range');
                          }
                        }

                        if (ageText.isNotEmpty) {
                          age = int.parse(ageText);
                          if (age <= 0 || age > 150) {
                            throw Exception('Invalid age range');
                          }
                        }

                        // Update profile with validated data
                        await controller.updateProfile(
                          name: name.isNotEmpty ? name : null,
                          bio: bio.isNotEmpty ? bio : null,
                          currentWeight: weight,
                          targetWeight: target,
                          userHeight: height,
                          userAge: age,
                        );

                        Get.back();
                      } catch (validationError) {
                        Get.snackbar(
                          '❌ Validation Error',
                          'Please enter valid data: ${validationError.toString()}',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: controller.isSaving.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildThemeSection() {
    final themeService = Get.find<ThemeService>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: AppTextStyles.headingMedium(Get.context!)),
          const SizedBox(height: 16),

          // Dark/Light Mode Toggle
          Obx(
            () => ListTile(
              leading: Icon(
                themeService.isDarkMode.value
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: AppColors.primary,
              ),
              title: Text('Dark Mode'),
              subtitle: Text(
                themeService.isDarkMode.value
                    ? 'Dark theme enabled'
                    : 'Light theme enabled',
              ),
              trailing: Switch(
                value: themeService.isDarkMode.value,
                onChanged: (_) => themeService.toggleThemeMode(),
              ),
            ),
          ),

          // Material 3 Toggle
          Obx(
            () => ListTile(
              leading: Icon(Icons.auto_awesome, color: AppColors.secondary),
              title: Text('Material 3'),
              subtitle: Text(
                themeService.useMaterial3.value
                    ? 'Material 3 enabled'
                    : 'Material 2 enabled',
              ),
              trailing: Switch(
                value: themeService.useMaterial3.value,
                onChanged: (_) => themeService.toggleMaterial3(),
              ),
            ),
          ),

          // Dynamic Color Toggle
          Obx(
            () => ListTile(
              leading: Icon(Icons.auto_fix_high, color: AppColors.tertiary),
              title: Text('Dynamic Colors'),
              subtitle: Text(
                themeService.useDynamicColor.value
                    ? 'Using system colors'
                    : 'Using custom colors',
              ),
              trailing: Switch(
                value: themeService.useDynamicColor.value,
                onChanged: (_) => themeService.toggleDynamicColor(),
              ),
            ),
          ),

          // Theme Settings Button
          ListTile(
            leading: Icon(Icons.palette, color: AppColors.primary),
            title: Text('Theme Settings'),
            subtitle: Text('Customize colors and appearance'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.to(() => const ThemeSettingsPage()),
          ),
        ],
      ),
    );
  }
}
