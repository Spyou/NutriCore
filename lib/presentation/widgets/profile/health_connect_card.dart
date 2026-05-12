import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';

/// Surfaces Health Connect state on the Profile screen. Three visual
/// states gated off [ProfileController]'s health Rx fields:
///
///   * unsupported  — Health Connect is not installed on the device.
///                    Shown as a muted info row, no actions.
///   * supported, not connected — Connect CTA that drives the system
///                                permission picker.
///   * connected    — Today's steps + active kcal, plus a Sync button.
///
/// Read-only: this widget never writes data back to Health Connect.
class HealthConnectCard extends StatelessWidget {
  const HealthConnectCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<ProfileController>();

    return Obx(() {
      final available = controller.healthAvailable.value;
      final connected = controller.healthConnected.value;

      return Container(
        decoration: BoxDecoration(
          // Subtle tinted surface so the card sits visually between the
          // neutral weight history card and the BMI indicator.
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context, scheme, textTheme, connected),
            const SizedBox(height: 14),
            if (!available)
              _unsupportedBody(scheme, textTheme)
            else if (!connected)
              _connectBody(context, controller, scheme, textTheme)
            else
              _connectedBody(controller, scheme, textTheme),
          ],
        ),
      );
    });
  }

  Widget _header(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    bool connected,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: 18,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health Connect',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                connected ? 'Synced today' : 'Read activity from your device',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (connected)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Connected',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _unsupportedBody(ColorScheme scheme, TextTheme textTheme) {
    final controller = Get.find<ProfileController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Health Connect provider not detected yet. If you just installed '
          'it, tap "Try again". Otherwise install or update Health Connect '
          'from the Play Store.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final busy = controller.isSyncingHealth.value;
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => controller.installHealthConnect(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.shop_rounded, size: 16),
                  label: const Text('Install / Update'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : () => controller.connectHealth(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Try again'),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _connectBody(
    BuildContext context,
    ProfileController controller,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Grant read access to steps, weight, and active calories so '
          'your dashboard reflects what you actually did today.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final busy = controller.isSyncingHealth.value;
          return FilledButton.icon(
            onPressed: busy ? null : () => controller.connectHealth(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                    ),
                  )
                : const Icon(Icons.link_rounded, size: 18),
            label: const Text('Connect Health'),
          );
        }),
      ],
    );
  }

  Widget _connectedBody(
    ProfileController controller,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() => _metricTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.directions_walk_rounded,
                    label: 'Steps',
                    value: _formatSteps(controller.healthStepsToday.value),
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => _metricTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.local_fire_department_rounded,
                    label: 'Active kcal',
                    value: controller.healthActiveCaloriesToday.value
                        .round()
                        .toString(),
                  )),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Obx(() {
          final busy = controller.isSyncingHealth.value;
          return OutlinedButton.icon(
            onPressed: busy ? null : () => controller.refreshHealthData(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: scheme.outlineVariant),
              foregroundColor: scheme.onSurface,
            ),
            icon: busy
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(scheme.onSurface),
                    ),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Sync now'),
          );
        }),
      ],
    );
  }

  Widget _metricTile({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(steps >= 10000 ? 0 : 1)}k';
    }
    return steps.toString();
  }
}
