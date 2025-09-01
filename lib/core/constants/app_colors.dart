import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColors {
  // Dynamic colors
  static Color get primary => Get.theme.colorScheme.primary;
  static Color get onPrimary => Get.theme.colorScheme.onPrimary;
  static Color get primaryContainer => Get.theme.colorScheme.primaryContainer;
  static Color get onPrimaryContainer =>
      Get.theme.colorScheme.onPrimaryContainer;

  static Color get secondary => Get.theme.colorScheme.secondary;
  static Color get onSecondary => Get.theme.colorScheme.onSecondary;
  static Color get secondaryContainer =>
      Get.theme.colorScheme.secondaryContainer;
  static Color get onSecondaryContainer =>
      Get.theme.colorScheme.onSecondaryContainer;

  static Color get tertiary => Get.theme.colorScheme.tertiary;
  static Color get onTertiary => Get.theme.colorScheme.onTertiary;
  static Color get tertiaryContainer => Get.theme.colorScheme.tertiaryContainer;
  static Color get onTertiaryContainer =>
      Get.theme.colorScheme.onTertiaryContainer;

  static Color get background => Get.theme.colorScheme.surface;
  static Color get onBackground => Get.theme.colorScheme.onSurface;
  static Color get surface => Get.theme.colorScheme.surface;
  static Color get onSurface => Get.theme.colorScheme.onSurface;
  static Color get surfaceVariant =>
      Get.theme.colorScheme.surfaceContainerHighest;
  static Color get onSurfaceVariant => Get.theme.colorScheme.onSurfaceVariant;

  static Color get error => Get.theme.colorScheme.error;
  static Color get onError => Get.theme.colorScheme.onError;
  static Color get errorContainer => Get.theme.colorScheme.errorContainer;
  static Color get onErrorContainer => Get.theme.colorScheme.onErrorContainer;

  static Color get outline => Get.theme.colorScheme.outline;
  static Color get outlineVariant => Get.theme.colorScheme.outlineVariant;
  static Color get shadow => Get.theme.colorScheme.shadow;
  static Color get scrim => Get.theme.colorScheme.scrim;
  static Color get inverseSurface => Get.theme.colorScheme.inverseSurface;
  static Color get onInverseSurface => Get.theme.colorScheme.onInverseSurface;
  static Color get inversePrimary => Get.theme.colorScheme.inversePrimary;

  // Legacy colors
  static Color get textPrimary => onSurface;
  static Color get textSecondary => onSurface.withOpacity(0.7);
  static Color get textTertiary => onSurface.withOpacity(0.5);
  static Color get textOnPrimary => onPrimary;

  // Semantic colors
  static Color get success =>
      Get.isDarkMode ? Colors.green.shade400 : Colors.green.shade600;
  static Color get warning =>
      Get.isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600;
  static Color get info =>
      Get.isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600;

  // Nutrition-specific colors
  static Color get calories =>
      Get.isDarkMode ? Colors.red.shade400 : Colors.red.shade600;
  static Color get proteins =>
      Get.isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600;
  static Color get carbs =>
      Get.isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600;
  static Color get fats =>
      Get.isDarkMode ? Colors.purple.shade400 : Colors.purple.shade600;

  static Color get sugar =>
      Get.isDarkMode ? Colors.pink.shade400 : Colors.pink.shade600;
  static Color get fiber =>
      Get.isDarkMode ? Colors.brown.shade400 : Colors.brown.shade600;
  static Color get salt =>
      Get.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

  static Color get nutriA => const Color(0xFF008000); // Green
  static Color get nutriB => const Color(0xFF85BB2F); // Light Green
  static Color get nutriC => const Color(0xFFFFFF00); // Yellow
  static Color get nutriD => const Color(0xFFFF8000); // Orange
  static Color get nutriE => const Color(0xFFFF0000); // Red

  // Gradient
  static List<Color> get primaryGradient => [primary, primary.withOpacity(0.8)];
  static List<Color> get backgroundGradient => [background, surfaceVariant];
}
