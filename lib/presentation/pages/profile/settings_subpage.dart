import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/theme_service.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/profile/edit_profile_sheet.dart';
import '../notification/notification_settings_page.dart';
import '../theme/theme_settings_page.dart';
import 'about_me.dart';

class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = Get.find<ProfileController>();
    final themeService = Get.find<ThemeService>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(
                scheme: scheme,
                textTheme: textTheme,
                title: 'Notifications',
                children: [
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.notifications_outlined,
                    iconColor: scheme.tertiary,
                    title: 'Notification settings',
                    subtitle: 'Customize meal reminders and alerts',
                    onTap: () =>
                        Get.to(() => const NotificationSettingsPage()),
                  ),
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: controller.weeklyReportsEnabled.value,
                        activeThumbColor: scheme.primary,
                        onChanged: (v) => controller.updateSettings(
                          weeklyReports: v,
                        ),
                        secondary: Icon(
                          Icons.insights_outlined,
                          color: scheme.tertiary,
                        ),
                        title: Text(
                          'Weekly reports',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Get weekly nutrition summaries',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                scheme: scheme,
                textTheme: textTheme,
                title: 'Appearance',
                children: [
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: themeService.isDarkMode.value,
                        activeThumbColor: scheme.primary,
                        onChanged: (_) => themeService.toggleThemeMode(),
                        secondary: Icon(
                          themeService.isDarkMode.value
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: scheme.primary,
                        ),
                        title: Text(
                          'Dark mode',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Switch between light and dark themes',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )),
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: themeService.useDynamicColor.value,
                        activeThumbColor: scheme.primary,
                        onChanged: (_) => themeService.toggleDynamicColor(),
                        secondary: Icon(
                          Icons.color_lens_outlined,
                          color: scheme.secondary,
                        ),
                        title: Text(
                          'Use system colors',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Match Android Material You',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )),
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.palette_outlined,
                    iconColor: scheme.tertiary,
                    title: 'Theme settings',
                    subtitle: 'Customize colors and seed',
                    onTap: () => Get.to(() => const ThemeSettingsPage()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                scheme: scheme,
                textTheme: textTheme,
                title: 'Account',
                children: [
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.edit_outlined,
                    iconColor: scheme.primary,
                    title: 'Edit profile',
                    subtitle: 'Update your name, bio and metrics',
                    onTap: () => EditProfileSheet.show(context),
                  ),
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.file_download_outlined,
                    iconColor: scheme.secondary,
                    title: 'Export data',
                    subtitle: 'Download a copy of your data',
                    onTap: controller.exportUserData,
                  ),
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.info_outline,
                    iconColor: scheme.tertiary,
                    title: 'About',
                    subtitle: 'App info and developer',
                    onTap: () => Get.to(() => const _AboutPage()),
                  ),
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.logout,
                    iconColor: scheme.error.withValues(alpha: 0.85),
                    title: 'Sign out',
                    subtitle: 'Sign out of your account',
                    titleColor: scheme.error.withValues(alpha: 0.85),
                    onTap: controller.signOut,
                  ),
                  _navTile(
                    scheme: scheme,
                    textTheme: textTheme,
                    icon: Icons.delete_forever_outlined,
                    iconColor: scheme.error,
                    title: 'Delete account',
                    subtitle: 'Permanently remove your account',
                    titleColor: scheme.error,
                    onTap: controller.deleteAccount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _navTile({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor ?? scheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'About',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: DeveloperAndDonationSection(),
        ),
      ),
    );
  }
}
