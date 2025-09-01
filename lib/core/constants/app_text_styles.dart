import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter';

  //dynamic text styles
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium(BuildContext context) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
    letterSpacing: -0.25,
  );

  // Heading Styles
  static TextStyle headingLarge(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  static TextStyle headingMedium(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  static TextStyle headingSmall(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  // Body Styles
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    fontFamily: fontFamily,
    height: 1.3,
  );

  // Label Styles
  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  static TextStyle labelMedium(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    fontFamily: fontFamily,
  );

  static TextStyle labelSmall(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  static TextTheme generateTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
        height: 1.3,
      ),
    );
  }

  static TextStyle error(BuildContext context) =>
      bodyMedium(context).copyWith(color: Theme.of(context).colorScheme.error);

  static TextStyle success(BuildContext context) =>
      bodyMedium(context).copyWith(color: Colors.green);

  static TextStyle warning(BuildContext context) =>
      bodyMedium(context).copyWith(color: Colors.orange);

  static TextStyle link(BuildContext context) => bodyMedium(context).copyWith(
    color: Theme.of(context).colorScheme.primary,
    decoration: TextDecoration.underline,
  );

  static TextStyle button(BuildContext context) => labelLarge(context).copyWith(
    color: Theme.of(context).colorScheme.onPrimary,
    fontWeight: FontWeight.w600,
  );

  static TextStyle caption(BuildContext context) => bodySmall(context).copyWith(
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    fontStyle: FontStyle.italic,
  );
}
