import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class AchievementDetailSheet extends StatelessWidget {
  const AchievementDetailSheet({super.key, required this.achievement});

  final Map<String, dynamic> achievement;

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> achievement,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementDetailSheet(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool unlocked = achievement['unlocked'] == true;
    final IconData icon = achievement['icon'] as IconData;
    final String title = achievement['title'] as String;
    final String description = achievement['description'] as String;
    final DateTime? unlockedAt = achievement['unlockedAt'] as DateTime?;
    final int progress = (achievement['progress'] as int?) ?? 0;
    final int progressMax = (achievement['progressMax'] as int?) ?? 1;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? null
                      : scheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                  gradient: unlocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.18),
                            scheme.primary.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 48,
                  color: unlocked
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _buildStatus(
                  context: context,
                  unlocked: unlocked,
                  unlockedAt: unlockedAt,
                  progress: progress,
                  progressMax: progressMax,
                  scheme: scheme,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(height: 20),
              if (unlocked)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: scheme.outlineVariant),
                          foregroundColor: scheme.onSurface,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'I just unlocked "$title" in NutriCore! '
                                  '$description',
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus({
    required BuildContext context,
    required bool unlocked,
    required DateTime? unlockedAt,
    required int progress,
    required int progressMax,
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    if (unlocked) {
      final dateLabel = unlockedAt != null
          ? DateFormat('MMM d, yyyy').format(unlockedAt)
          : '';
      return Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unlocked $dateLabel',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      );
    }

    if (progressMax > 1) {
      final ratio =
          (progress / progressMax).clamp(0.0, 1.0).toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Text(
                '$progress/$progressMax',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: ratio,
                color: scheme.primary,
                backgroundColor:
                    scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: scheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Not yet unlocked',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
