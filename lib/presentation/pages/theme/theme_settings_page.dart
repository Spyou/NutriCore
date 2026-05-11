import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/services/theme_service.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';

class ThemeSettingsPage extends GetView<ThemeService> {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Theme Settings',
          style: textTheme.titleLarge,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: scheme.onSurface),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: scheme.primary),
            onPressed: () => controller.resetToDefaults(),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThemePreview(context),
            const SizedBox(height: 24),
            _buildThemeModeSection(context),
            const SizedBox(height: 20),
            _buildMaterial3Section(context),
            const SizedBox(height: 20),
            _buildDynamicColorSection(context),
            const SizedBox(height: 20),
            _buildColorSelectionSection(context),
            const SizedBox(height: 20),
            _buildPresetThemesSection(context),
            const SizedBox(height: 20),
            _buildAdvancedOptionsSection(context),
            const SizedBox(height: 20),
            _buildActionsSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
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
              Icon(Icons.preview, color: scheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Theme Preview',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPreviewCard(
                  context,
                  'Primary',
                  Icons.palette,
                  scheme.primaryContainer,
                  scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  'Secondary',
                  Icons.color_lens,
                  scheme.secondaryContainer,
                  scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  'Tertiary',
                  Icons.brush,
                  scheme.tertiaryContainer,
                  scheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.themeIcon,
                    color: scheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.themeStatusText,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.useMaterial3.value ? 'M3' : 'M2',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildPreviewCard(
    BuildContext context,
    String label,
    IconData icon,
    Color backgroundColor,
    Color textColor,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _buildSection(
      context,
      title: 'Theme Mode',
      icon: Icons.brightness_6,
      iconColor: scheme.primary,
      child: Obx(
        () => Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Dark Mode', style: textTheme.bodyLarge),
              subtitle: Text(
                controller.isDarkMode.value
                    ? 'Dark theme reduces eye strain in low light'
                    : 'Light theme provides better visibility',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              value: controller.isDarkMode.value,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                controller.toggleThemeMode();
              },
              secondary: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  controller.isDarkMode.value
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  key: ValueKey(controller.isDarkMode.value),
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              controller.isDarkMode.value
                  ? 'Dark mode can help reduce battery usage on OLED displays and may be easier on your eyes in low-light environments.'
                  : 'Light mode provides excellent readability in bright environments and is the traditional interface style.',
              controller.isDarkMode.value
                  ? Icons.battery_saver
                  : Icons.wb_sunny,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterial3Section(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _buildSection(
      context,
      title: 'Material Design',
      icon: Icons.auto_awesome,
      iconColor: scheme.secondary,
      child: Obx(
        () => Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Material 3 Design',
                style: textTheme.bodyLarge,
              ),
              subtitle: Text(
                controller.useMaterial3.value
                    ? 'Modern Material 3 design system with dynamic colors'
                    : 'Classic Material 2 design with traditional styling',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              value: controller.useMaterial3.value,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                controller.toggleMaterial3();
              },
              secondary: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.useMaterial3.value
                      ? scheme.secondary.withValues(alpha: 0.1)
                      : scheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.useMaterial3.value
                      ? Icons.new_releases
                      : Icons.history,
                  color: controller.useMaterial3.value
                      ? scheme.secondary
                      : scheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureComparison(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design System Features:',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Column(
              children: [
                _buildFeatureRow(
                  context,
                  'Dynamic Colors',
                  controller.useMaterial3.value,
                ),
                _buildFeatureRow(
                  context,
                  'Enhanced Components',
                  controller.useMaterial3.value,
                ),
                _buildFeatureRow(
                  context,
                  'Better Accessibility',
                  controller.useMaterial3.value,
                ),
                _buildFeatureRow(
                  context,
                  'Modern Typography',
                  controller.useMaterial3.value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String feature, bool enabled) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: enabled ? scheme.tertiary : scheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: textTheme.bodySmall?.copyWith(
              color: enabled
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicColorSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _buildSection(
      context,
      title: 'Dynamic Colors',
      icon: Icons.auto_fix_high,
      iconColor: scheme.tertiary,
      child: Obx(
        () => Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'System Colors',
                style: textTheme.bodyLarge,
              ),
              subtitle: Text(
                controller.useDynamicColor.value
                    ? 'Colors automatically adapt to your wallpaper'
                    : 'Using custom app color scheme',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              value: controller.useDynamicColor.value,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                controller.toggleDynamicColor();
              },
              secondary: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: controller.useDynamicColor.value
                      ? LinearGradient(
                          colors: [
                            scheme.tertiary.withValues(alpha: 0.3),
                            scheme.primary.withValues(alpha: 0.3),
                          ],
                        )
                      : null,
                  color: controller.useDynamicColor.value
                      ? null
                      : scheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.useDynamicColor.value
                      ? Icons.wallpaper
                      : Icons.color_lens,
                  color: controller.useDynamicColor.value
                      ? scheme.tertiary
                      : scheme.outline,
                ),
              ),
            ),
            if (!controller.useDynamicColor.value) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Dynamic colors are disabled. You can customize the app colors using the color picker below.',
                Icons.info_outline,
              ),
            ] else ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                'Dynamic colors automatically extract colors from your device wallpaper to create a personalized color scheme.',
                Icons.palette,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelectionSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: controller.useDynamicColor.value
            ? const SizedBox.shrink()
            : _buildSection(
                context,
                title: 'Custom Colors',
                icon: Icons.palette,
                iconColor: scheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your preferred color scheme:',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildColorGrid(context),
                    const SizedBox(height: 16),
                    _buildCustomColorPicker(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildColorGrid(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: controller.presetColors.map((color) {
        return Obx(() => _buildColorOption(context, color));
      }).toList(),
    );
  }

  Widget _buildColorOption(BuildContext context, Color color) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = controller.seedColor.value == color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.changeSeedColor(color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? scheme.onSurface : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: isSelected
            ? Icon(Icons.check, color: _getContrastColor(color), size: 24)
            : null,
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    // Contrast color for arbitrary swatch: kept literal for legibility on a
    // user-chosen color (not a theme token).
    return luminance > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  Widget _buildCustomColorPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Color',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to pick any color you like',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                // Rainbow gradient is the visual identity of the color picker
                // and must show actual hues, not theme tokens.
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE53935),
                    Color(0xFFFB8C00),
                    Color(0xFFFDD835),
                    Color(0xFF43A047),
                    Color(0xFF1E88E5),
                    Color(0xFF3949AB),
                    Color(0xFF8E24AA),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.colorize, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Pick Custom Color',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetThemesSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSection(
      context,
      title: 'Preset Themes',
      icon: Icons.style,
      iconColor: scheme.secondary,
      // Preset swatches must show their actual seed color, not theme tokens.
      child: Column(
        children: [
          _buildPresetTheme(
              context, 'Nature', const Color(0xFF2E7D32), Icons.eco),
          const SizedBox(height: 8),
          _buildPresetTheme(
              context, 'Ocean', const Color(0xFF1565C0), Icons.waves),
          const SizedBox(height: 8),
          _buildPresetTheme(
            context,
            'Sunset',
            const Color(0xFFEF6C00),
            Icons.wb_twilight,
          ),
          const SizedBox(height: 8),
          _buildPresetTheme(
            context,
            'Berry',
            const Color(0xFF8E24AA),
            Icons.local_florist,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTheme(
    BuildContext context,
    String name,
    Color color,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.changeSeedColor(color);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.seedColor.value == color
                ? color
                : scheme.outline.withValues(alpha: 0.2),
            width: controller.seedColor.value == color ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (controller.seedColor.value == color)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSection(
      context,
      title: 'Advanced Options',
      icon: Icons.settings,
      iconColor: scheme.tertiary,
      child: Column(
        children: [
          _buildAdvancedOption(
            context,
            'High Contrast',
            'Increase color contrast for better accessibility',
            Icons.contrast,
            false,
            (value) {},
          ),
          const SizedBox(height: 12),
          _buildAdvancedOption(
            context,
            'Reduce Animations',
            'Minimize animations for better performance',
            Icons.animation,
            false,
            (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.tertiary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildSection(
      context,
      title: 'Actions',
      icon: Icons.build,
      iconColor: scheme.primary,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _exportThemeSettings(context),
              icon: const Icon(Icons.file_download),
              label: const Text('Export Theme Settings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String text, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.refresh, color: scheme.error),
            const SizedBox(width: 12),
            Text(
              'Reset Theme Settings',
              style: textTheme.titleMedium,
            ),
          ],
        ),
        content: Text(
          'This will reset all theme settings to their default values. Are you sure you want to continue?',
          style: textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.outline,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Color selectedColor = controller.seedColor.value;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pick a Color', style: textTheme.titleMedium),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: Colors.primaries.length,
            itemBuilder: (context, index) {
              // Swatch grid intentionally shows real material primary hues —
              // these are the choices the user picks from.
              final color = Colors.primaries[index];
              return GestureDetector(
                onTap: () {
                  selectedColor = color;
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedColor == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.changeSeedColor(selectedColor);
              Get.back();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportThemeSettings(BuildContext context) {
    final themeInfo = controller.currentThemeInfo;
    CustomThemeFlushbar.show(
      title: 'Theme Settings',
      message: 'Theme configuration exported: $themeInfo',
    );
  }
}
