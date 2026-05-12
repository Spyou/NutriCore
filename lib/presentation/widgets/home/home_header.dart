import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/meal_entry.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/nutrition_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../pages/home/ai_meal_analysis_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _greetingLabel(int hour) {
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Midday';
    if (hour < 21) return 'Evening';
    return 'Late night';
  }

  IconData _greetingIcon(int hour) {
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    if (hour < 21) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.characters.first.toUpperCase();
  }

  /// Prefer the ProfileController-backed name (reactive, sourced from
  /// Firestore) over HomeController's getter, which only reads from
  /// FirebaseAuth's cached `displayName` and can be stale right after
  /// signup. Falls back through ProfileController.userEmail → HomeController.
  String _resolveName(HomeController home, ProfileController? profile) {
    final fromProfile = profile?.userName.value.trim() ?? '';
    if (fromProfile.isNotEmpty &&
        fromProfile != 'Anonymous User' &&
        fromProfile != 'User') {
      return fromProfile;
    }
    final fromHome = home.userName.trim();
    if (fromHome.isNotEmpty &&
        fromHome != 'Anonymous User' &&
        fromHome != 'User') {
      return fromHome;
    }
    return '';
  }

  String _formatRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? '${h}h ${m}m ago' : '${h}h ago';
    }
    return DateFormat.MMMd().format(t);
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      '·',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildContextLine(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nutrition = Get.find<NutritionController>();
    final ProfileController? profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    final baseStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
    );

    return Obx(() {
      final meals = nutrition.todayMeals;
      final streak = profile?.streakDays.value ?? 0;

      final List<Widget> parts = [];

      if (meals.isNotEmpty) {
        final sorted = List<MealEntry>.from(meals)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final last = sorted.first;
        if (streak > 0) {
          parts.addAll([
            Text('Day $streak on track', style: baseStyle),
            _dot(),
            Flexible(
              child: Text(
                _formatRelative(last.timestamp),
                style: baseStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ]);
        } else {
          parts.add(
            Flexible(
              child: Text(
                'Last logged · ${last.name}, ${_formatRelative(last.timestamp)}',
                style: baseStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }
      } else if (streak > 0) {
        parts.addAll([
          Text('Day $streak on track', style: baseStyle),
          _dot(),
          Text('ready when you are', style: baseStyle),
        ]);
      } else {
        parts.add(
          Text('Snap a meal to start tracking.', style: baseStyle),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: parts,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<HomeController>();
    final hour = DateTime.now().hour;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.85),
            scheme.secondary.withValues(alpha: 0.7),
            scheme.tertiary.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
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
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _greetingIcon(hour),
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _greetingLabel(hour),
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        final profile = Get.isRegistered<ProfileController>()
                            ? Get.find<ProfileController>()
                            : null;
                        final photoUrl =
                            profile?.profileImageUrl.value.trim() ?? '';
                        final name = _resolveName(controller, profile);
                        final initial = _initial(name);
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: photoUrl.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                    placeholder: (_, __) => Center(
                                      child: Text(
                                        initial,
                                        style: textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Center(
                                      child: initial.isEmpty
                                          ? const Icon(
                                              Icons.person_outline_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            )
                                          : Text(
                                              initial,
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                )
                              : (initial.isEmpty
                                  ? const Icon(
                                      Icons.person_outline_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    )
                                  : Text(
                                      initial,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final profile = Get.isRegistered<ProfileController>()
                        ? Get.find<ProfileController>()
                        : null;
                    final name = _resolveName(controller, profile).trim();
                    final display = name.isEmpty ? 'Hey there.' : '$name.';
                    return Text(
                      display,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -0.8,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildContextLine(context),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Get.to(() => const AIMealAnalysisPage());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Snap a meal',
                                style: textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
