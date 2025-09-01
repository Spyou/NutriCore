import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/constants/app_colors.dart';
import 'package:nutri_check/core/constants/app_text_styles.dart';
import 'package:nutri_check/core/services/theme_service.dart';

class ThemeSettingsPage extends GetView<ThemeService> {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Theme Settings',
          style: AppTextStyles.headingMedium(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.onSurface),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
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

  // 🔥 Theme Preview Section
  Widget _buildThemePreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
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
              Icon(Icons.preview, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Theme Preview',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
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
                  AppColors.primaryContainer,
                  AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  'Secondary',
                  Icons.color_lens,
                  AppColors.secondaryContainer,
                  AppColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  'Tertiary',
                  Icons.brush,
                  AppColors.tertiaryContainer,
                  AppColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.themeIcon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.themeStatusText,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.useMaterial3.value ? 'M3' : 'M2',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: AppColors.primary,
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
            style: AppTextStyles.labelMedium(
              context,
            ).copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 🔥 Theme Mode Toggle Section
  Widget _buildThemeModeSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Theme Mode',
      icon: Icons.brightness_6,
      iconColor: AppColors.primary,
      child: Obx(
        () => Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Dark Mode', style: AppTextStyles.bodyLarge(context)),
              subtitle: Text(
                controller.isDarkMode.value
                    ? 'Dark theme reduces eye strain in low light'
                    : 'Light theme provides better visibility',
                style: AppTextStyles.bodySmall(context),
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
                  color: AppColors.primary,
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

  // 🔥 Material 3 Toggle Section
  Widget _buildMaterial3Section(BuildContext context) {
    return _buildSection(
      context,
      title: 'Material Design',
      icon: Icons.auto_awesome,
      iconColor: AppColors.secondary,
      child: Obx(
        () => Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Material 3 Design',
                style: AppTextStyles.bodyLarge(context),
              ),
              subtitle: Text(
                controller.useMaterial3.value
                    ? 'Modern Material 3 design system with dynamic colors'
                    : 'Classic Material 2 design with traditional styling',
                style: AppTextStyles.bodySmall(context),
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
                      ? AppColors.secondary.withOpacity(0.1)
                      : AppColors.outline.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.useMaterial3.value
                      ? Icons.new_releases
                      : Icons.history,
                  color: controller.useMaterial3.value
                      ? AppColors.secondary
                      : AppColors.outline,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design System Features:',
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: enabled ? AppColors.success : AppColors.outline,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: enabled
                  ? AppColors.onSurface
                  : AppColors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Dynamic Color Toggle Section
  Widget _buildDynamicColorSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Dynamic Colors',
      icon: Icons.auto_fix_high,
      iconColor: AppColors.tertiary,
      child: Obx(
        () => Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'System Colors',
                style: AppTextStyles.bodyLarge(context),
              ),
              subtitle: Text(
                controller.useDynamicColor.value
                    ? 'Colors automatically adapt to your wallpaper'
                    : 'Using custom app color scheme',
                style: AppTextStyles.bodySmall(context),
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
                            AppColors.tertiary.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.3),
                          ],
                        )
                      : null,
                  color: controller.useDynamicColor.value
                      ? null
                      : AppColors.outline.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  controller.useDynamicColor.value
                      ? Icons.wallpaper
                      : Icons.color_lens,
                  color: controller.useDynamicColor.value
                      ? AppColors.tertiary
                      : AppColors.outline,
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

  // 🔥 Color Selection Section
  Widget _buildColorSelectionSection(BuildContext context) {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: controller.useDynamicColor.value
            ? const SizedBox.shrink()
            : _buildSection(
                context,
                title: 'Custom Colors',
                icon: Icons.palette,
                iconColor: AppColors.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your preferred color scheme:',
                      style: AppTextStyles.bodyMedium(context),
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
            color: isSelected ? AppColors.onSurface : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
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
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildCustomColorPicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Color',
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to pick any color you like',
            style: AppTextStyles.bodySmall(context),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline.withOpacity(0.3)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.colorize, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Pick Custom Color',
                      style: AppTextStyles.labelLarge(context).copyWith(
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

  // 🔥 Preset Themes Section
  Widget _buildPresetThemesSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Preset Themes',
      icon: Icons.style,
      iconColor: AppColors.secondary,
      child: Column(
        children: [
          _buildPresetTheme(context, 'Nature', Colors.green, Icons.eco),
          const SizedBox(height: 8),
          _buildPresetTheme(context, 'Ocean', Colors.blue, Icons.waves),
          const SizedBox(height: 8),
          _buildPresetTheme(
            context,
            'Sunset',
            Colors.orange,
            Icons.wb_twilight,
          ),
          const SizedBox(height: 8),
          _buildPresetTheme(
            context,
            'Berry',
            Colors.purple,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.changeSeedColor(color);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.seedColor.value == color
                ? color
                : AppColors.outline.withOpacity(0.2),
            width: controller.seedColor.value == color ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (controller.seedColor.value == color)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  // 🔥 Advanced Options Section
  Widget _buildAdvancedOptionsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Advanced Options',
      icon: Icons.settings,
      iconColor: AppColors.tertiary,
      child: Column(
        children: [
          _buildAdvancedOption(
            context,
            'High Contrast',
            'Increase color contrast for better accessibility',
            Icons.contrast,
            false, // You can add this to ThemeService if needed
            (value) {
              // Handle high contrast toggle
            },
          ),
          const SizedBox(height: 12),
          _buildAdvancedOption(
            context,
            'Reduce Animations',
            'Minimize animations for better performance',
            Icons.animation,
            false, // You can add this to ThemeService if needed
            (value) {
              // Handle animation toggle
            },
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tertiary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                Text(subtitle, style: AppTextStyles.bodySmall(context)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // 🔥 Actions Section
  Widget _buildActionsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Actions',
      icon: Icons.build,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
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

  // 🔥 Helper Widgets
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.headingSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.primary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Dialog Methods
  void _showResetDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.refresh, color: AppColors.warning),
            const SizedBox(width: 12),
            Text(
              'Reset Theme Settings',
              style: AppTextStyles.headingSmall(context),
            ),
          ],
        ),
        content: Text(
          'This will reset all theme settings to their default values. Are you sure you want to continue?',
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(
                context,
              ).copyWith(color: AppColors.outline),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Color selectedColor = controller.seedColor.value;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pick a Color', style: AppTextStyles.headingSmall(context)),
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

    Get.snackbar(
      '💾 Theme Settings',
      'Theme configuration exported successfully',
      duration: const Duration(seconds: 3),
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme configuration exported:',
            style: TextStyle(color: Colors.white),
          ),
          Text(
            themeInfo.toString(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
