import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import 'achievement_detail_sheet.dart';

class AchievementsRow extends StatelessWidget {
  const AchievementsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = Get.find<ProfileController>();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Achievements',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Obx(() {
                final list = profile.achievements;
                final total = list.length;
                final unlocked =
                    list.where((a) => a['unlocked'] == true).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$unlocked/$total',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 12,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Obx(() {
              final list = profile.achievements;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _AchievementBadge(achievement: list[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});

  final Map<String, dynamic> achievement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool unlocked = achievement['unlocked'] == true;
    final IconData icon = achievement['icon'] as IconData;
    final String title = achievement['title'] as String;

    return SizedBox(
      width: 88,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              AchievementDetailSheet.show(context, achievement),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: unlocked
                      ? scheme.primary.withValues(alpha: 0.14)
                      : scheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: unlocked
                      ? null
                      : Border.all(color: scheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 28,
                  color: unlocked
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unlocked
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.55),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
