import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../../pages/auth/onboarding_page.dart';

/// Compact nudge shown on Home when a user finished onboarding with
/// defaults (skipped) or hasn't filled out enough profile detail for
/// meaningful daily targets. Tapping reopens the onboarding flow so
/// they can complete it on their own time. Hides itself automatically
/// once profileCompleteness reaches the threshold.
class CompleteProfileBanner extends StatelessWidget {
  const CompleteProfileBanner({super.key});

  static const double _threshold = 0.5;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : null;
      if (profile == null) return const SizedBox.shrink();
      if (profile.profileCompleteness.value >= _threshold) {
        return const SizedBox.shrink();
      }
      final scheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      final percent = (profile.profileCompleteness.value * 100).round();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Get.to(() => const OnboardingPage()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.tertiaryContainer.withValues(alpha: 0.55),
                    scheme.primaryContainer.withValues(alpha: 0.45),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete your profile',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Profile $percent% complete · '
                          'finish for accurate goals',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
