import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';
import 'package:nutri_check/presentation/pages/profile/about_me.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/profile/achievements_row.dart';
import '../../widgets/profile/bmi_indicator.dart';
import '../../widgets/profile/edit_profile_sheet.dart';
import '../../widgets/profile/health_connect_card.dart';
import '../../widgets/profile/weekly_summary_card.dart';
import '../../widgets/profile/weight_history_card.dart';
import 'settings_subpage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: Get.find<ProfileController>(),
      builder: (controller) => Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            final nutritionController = Get.find<NutritionController>();
            final profileController = Get.find<ProfileController>();

            await nutritionController.refreshData();
            await profileController.refreshStats();
            await profileController.refreshHealthData();
          },
          child: Obx(
            () => controller.isLoading.value
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(controller),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _buildProfileCard(context, controller),
                            const SizedBox(height: 16),
                            _buildStatsRow(context, controller),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: WeightHistoryCard(),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: HealthConnectCard(),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: BmiIndicator(),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: WeeklySummaryCard(),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: AchievementsRow(),
                            ),
                            const SizedBox(height: 16),
                            _buildSettingsRow(context),
                            const SizedBox(height: 24),
                            _developerInfo(context),
                            const SizedBox(height: 20),
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
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha:
                    0.95 + (0.05 * shrinkPercentage),
                  ),
                  AppColors.tertiary.withValues(alpha:
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                          ? Obx(
                              () => Text(
                                controller.userName.value.isNotEmpty
                                    ? controller.userName.value
                                    : 'Profile',
                                key: const ValueKey('collapsed_profile'),
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
                        padding: const EdgeInsets.only(left: 20, right: 60, top: 8),
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
                                      const SizedBox(height: 2),
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
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
                                                const SizedBox(width: 8),
                                                Text(
                                                  'since ${_formatDate(controller.joinDate.value)}',
                                                  style:
                                                      AppTextStyles.bodyMedium(
                                                        Get.context!,
                                                      ).copyWith(
                                                        color: AppColors
                                                            .textOnPrimary
                                                            .withValues(alpha: 0.9),
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
                            const SizedBox(height: 8),
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
    );
  }

  Widget _buildProfileCard(BuildContext context, ProfileController controller) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget avatarFallback() => Container(
      color: scheme.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: scheme.primary.withValues(alpha: 0.4),
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Obx(
                    () => SizedBox(
                      width: 64,
                      height: 64,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: controller.profileImageUrl.value.isEmpty
                            ? avatarFallback()
                            : CachedNetworkImage(
                                imageUrl: controller.profileImageUrl.value,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => avatarFallback(),
                                errorWidget: (_, __, ___) => avatarFallback(),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: controller.updateProfileImage,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Obx(
                          () => controller.isUploadingImage.value
                              ? SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    color: scheme.onPrimary,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_rounded,
                                  color: scheme.onPrimary,
                                  size: 14,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.userName.value,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => Text(
                        controller.userEmail.value,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(
            () => controller.userBio.value.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      controller.userBio.value,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => EditProfileSheet.show(context),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ProfileController controller) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              context,
              icon: Icons.restaurant_menu_rounded,
              accent: scheme.primary,
              label: 'Meals logged',
              valueBuilder: () =>
                  Obx(() => _statValueText(context, controller.totalMealsLogged.value.toString())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              context,
              icon: Icons.local_fire_department_rounded,
              accent: scheme.primary,
              label: 'Streak days',
              valueBuilder: () =>
                  Obx(() => _statValueText(context, controller.streakDays.value.toString())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              context,
              icon: Icons.calendar_month_rounded,
              accent: scheme.tertiary,
              label: 'This week',
              valueBuilder: () {
                final nutrition = Get.find<NutritionController>();
                return Obx(() {
                  final count = nutrition.weekCalories
                      .where((c) => c > 0)
                      .length;
                  return _statValueText(context, '$count / 7');
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statValueText(BuildContext context, String value) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      value,
      style: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String label,
    required Widget Function() valueBuilder,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 12),
          valueBuilder(),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.to(() => const SettingsSubPage()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.settings_outlined,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Notifications, appearance, account',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _developerInfo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Text(
            'Developer',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const DeveloperAndDonationSection(),
      ],
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
}
