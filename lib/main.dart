import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/presentation/services/firebase_notification_service.dart';

import 'core/config/off_config.dart';
import 'core/services/theme_service.dart';
import 'firebase_options.dart';
import 'presentation/bindings/app_binding.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    await GetStorage.init();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize ThemeService
    await Get.putAsync<ThemeService>(() async {
      final service = ThemeService();
      await service.onInit();
      return service;
    });

    // Initialize OpenFoodFacts
    OpenFoodFactsConfig.initialize();
    await _setInitialSystemUI();

    Get.put(NotificationService(), permanent: true);

    runApp(const MyApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Stack trace: $stackTrace');
    }

    runApp(ErrorApp(error: e.toString()));
  }
}

Future<void> _setInitialSystemUI() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = Get.find<ThemeService>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        if (lightDynamic != null && darkDynamic != null) {
          themeService.systemDynamicColors.value = lightDynamic;
        }

        return Obx(() {
          _updateSystemUI(themeService.isDarkMode.value);

          return GetMaterialApp(
            title: 'NutriCheck',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            initialBinding: AppBinding(),
            home: const SplashPage(),
            // Localization
            locale: Get.deviceLocale,
            fallbackLocale: const Locale('en', 'US'),
            // Navigation & Transitions
            defaultTransition: Transition.cupertino,
            transitionDuration: const Duration(milliseconds: 300),
            smartManagement: SmartManagement.keepFactory,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.4),
                  ),
                ),
                child: child!,
              );
            },
          );
        });
      },
    );
  }

  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? const Color(0xFF1C1B1F)
            : Colors.white,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: isDark
            ? const Color(0xFF48464C)
            : const Color(0xFFE7E0EC),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriCheck - Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 72, color: Colors.red.shade400),
                const SizedBox(height: 24),
                Text(
                  'Failed to Initialize App',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'An error occurred during app initialization. Please restart the app.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error Details:\n$error',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
