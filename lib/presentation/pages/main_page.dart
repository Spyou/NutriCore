import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/constants/app_colors.dart';
import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:nutri_check/presentation/pages/home/home_page.dart';
import 'package:nutri_check/presentation/pages/nutrition/nutrition_page.dart';
import 'package:nutri_check/presentation/pages/profile/profile_page.dart';
import 'package:nutri_check/presentation/pages/scan/scan_page.dart';
import 'package:nutri_check/presentation/pages/search/search_page.dart';

class MainPage extends GetView<MainController> {
  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    ScanPage(),
    NutritionPage(),
    ProfilePage(),
  ];

  MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: (int index) {
            HapticFeedback.lightImpact();
            controller.changeIndex(index);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          elevation: 8,
          height: 80,

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Nutrition',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
