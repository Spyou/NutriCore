import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/constants/app_text_styles.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';

class ThemeService extends GetxService {
  final _box = GetStorage();

  static const String _themeKey = 'theme_mode';
  static const String _material3Key = 'use_material3';
  static const String _dynamicColorKey = 'use_dynamic_color';
  static const String _seedColorKey = 'seed_color';

  var isDarkMode = false.obs;
  var useMaterial3 = true.obs;
  var useDynamicColor = true.obs;
  Rx<Color> seedColor = Rx<Color>(Colors.green);
  var systemDynamicColors = Rx<ColorScheme?>(null);

  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;

  ThemeData get lightTheme =>
      _cachedLightTheme ??= _buildTheme(Brightness.light);
  ThemeData get darkTheme => _cachedDarkTheme ??= _buildTheme(Brightness.dark);

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initStorage();
    await _loadSettings();
    await _loadDynamicColors();
  }

  Future<void> _initStorage() async {
    await GetStorage.init();
  }

  Future<void> _loadSettings() async {
    try {
      isDarkMode.value = _box.read(_themeKey) ?? false;
      useMaterial3.value = _box.read(_material3Key) ?? true;
      useDynamicColor.value = _box.read(_dynamicColorKey) ?? true;

      final savedColorValue = _box.read(_seedColorKey);
      if (savedColorValue != null) {
        seedColor.value = Color(savedColorValue);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading theme settings: $e');
      }
    }
  }

  Future<void> _loadDynamicColors() async {
    try {
      systemDynamicColors.value = null;
      if (kDebugMode) {
        print('Dynamic colors');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Dynamic colors not available: $e');
      }
    }
  }

  void toggleThemeMode() {
    isDarkMode.value = !isDarkMode.value;
    _saveThemeMode();
    _applyTheme();

    CustomThemeFlushbar.show(
      title:
          'Theme Changed : ${isDarkMode.value ? 'Dark mode activated' : 'Light mode activated'}',
      message: 'please restart the app to see full effect',
    );
  }

  void toggleMaterial3() {
    useMaterial3.value = !useMaterial3.value;
    _saveMaterial3Setting();
    _invalidateCache();
    _applyTheme();
    CustomThemeFlushbar.show(
      title: 'Material Design Changed',
      message: 'please restart the app to see full effect',
    );
  }

  void toggleDynamicColor() {
    useDynamicColor.value = !useDynamicColor.value;
    _saveDynamicColorSetting();
    _invalidateCache();
    _applyTheme();

    CustomThemeFlushbar.show(
      title: 'Dynamic Color Changed',
      message: 'please restart the app to see full effect',
    );
  }

  void changeSeedColor(Color color) {
    seedColor.value = color;
    _saveSeedColor();
    _invalidateCache();
    _applyTheme();

    CustomThemeFlushbar.show(
      title: 'Color Updated',
      message: 'please restart the app to see full effect',
    );
  }

  void _applyTheme() {
    Get.changeThemeMode(themeMode);
  }

  void _invalidateCache() {
    _cachedLightTheme = null;
    _cachedDarkTheme = null;
  }

  /// Public hook so callers (e.g. the DynamicColorBuilder in `main.dart`)
  /// can drop the cached themes when the system palette becomes available.
  void invalidateThemeCache() {
    _invalidateCache();
  }

  void _saveThemeMode() => _box.write(_themeKey, isDarkMode.value);
  void _saveMaterial3Setting() => _box.write(_material3Key, useMaterial3.value);
  void _saveDynamicColorSetting() =>
      _box.write(_dynamicColorKey, useDynamicColor.value);
  void _saveSeedColor() =>
      _box.write(_seedColorKey, seedColor.value.toARGB32());

  ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme;
    if (useDynamicColor.value && systemDynamicColors.value != null) {
      if (brightness == Brightness.light) {
        colorScheme = systemDynamicColors.value!;
      } else {
        colorScheme = ColorScheme.fromSeed(
          seedColor: Color(systemDynamicColors.value!.primary.toARGB32()),
          brightness: brightness,
        );
      }
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor.value,
        brightness: brightness,
      );
    }

    return ThemeData(
      useMaterial3: useMaterial3.value,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: AppTextStyles.generateTextTheme(colorScheme),
      fontFamily: AppTextStyles.fontFamily,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: useMaterial3.value ? 1 : 2,
          shadowColor: colorScheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(useMaterial3.value ? 20 : 8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: useMaterial3.value ? 1 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(useMaterial3.value ? 12 : 8),
        ),
        color: colorScheme.surface,
        shadowColor: colorScheme.shadow,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: useMaterial3.value ? 3 : 4,
        centerTitle: false,
        titleTextStyle: AppTextStyles.generateTextTheme(
          colorScheme,
        ).headlineSmall,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(useMaterial3.value ? 12 : 8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(useMaterial3.value ? 12 : 8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(useMaterial3.value ? 12 : 8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(useMaterial3.value ? 12 : 8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: useMaterial3.value ? 3 : 8,
      ),
    );
  }

  List<Color> get presetColors => [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.red,
    Colors.amber,
    Colors.cyan,
  ];

  void resetToDefaults() {
    isDarkMode.value = false;
    useMaterial3.value = true;
    useDynamicColor.value = true;
    seedColor.value = Colors.green;

    _saveThemeMode();
    _saveMaterial3Setting();
    _saveDynamicColorSetting();
    _saveSeedColor();
    _invalidateCache();
    _applyTheme();

    CustomThemeFlushbar.show(
      title: 'Settings Reset',
      message: 'please restart the app to see full effect',
    );
  }

  Color get surfaceColor =>
      Get.isDarkMode ? const Color(0xFF1C1B1F) : Colors.white;
  Color get onSurfaceColor => Get.isDarkMode ? Colors.white : Colors.black;
  Color get primaryColor => seedColor.value;
  Color get errorColor =>
      Get.isDarkMode ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  Color get successColor =>
      Get.isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get warningColor =>
      Get.isDarkMode ? const Color(0xFFFF9800) : const Color(0xFFF57C00);

  bool get isLight => !isDarkMode.value;
  bool get isDark => isDarkMode.value;
  String get themeStatusText =>
      isDarkMode.value ? 'Dark Theme Active' : 'Light Theme Active';

  IconData get themeIcon =>
      isDarkMode.value ? Icons.dark_mode : Icons.light_mode;

  Map<String, dynamic> get currentThemeInfo => {
    'isDarkMode': isDarkMode.value,
    'useMaterial3': useMaterial3.value,
    'useDynamicColor': useDynamicColor.value,
    'seedColor': seedColor.value.toARGB32().toRadixString(16),
    'themeMode': themeMode.toString(),
  };
}
