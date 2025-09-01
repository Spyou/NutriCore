import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/entities/product.dart';
import 'auth_controller.dart';
import 'nutrition_controller.dart';

class HomeController extends GetxController {
  final NutritionController nutritionController = Get.find();
  final AuthController authController = Get.find();

  var isLoading = false.obs;
  var recentProducts = <Product>[].obs;
  var todayIntake = Rxn<TodayIntakeModel>();

  @override
  void onInit() {
    super.onInit();
    loadHomeData();
  }

  Future<void> refreshData() async {
    await loadHomeData();
  }

  Future<void> loadHomeData() async {
    try {
      isLoading.value = true;
      await nutritionController.loadDataFromFirebase();

      _calculateTodayIntake();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading home data: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateTodayIntake() {
    final meals = nutritionController.todayMeals;
    double totalCalories = nutritionController.totalCalories.value;
    double totalProteins = nutritionController.totalProteins.value;
    double totalCarbs = nutritionController.totalCarbs.value;
    double totalFats = nutritionController.totalFats.value;

    todayIntake.value = TodayIntakeModel(
      totalCalories: totalCalories,
      totalNutrition: NutritionSummary(
        proteins100g: totalProteins,
        carbohydrates100g: totalCarbs,
        fat100g: totalFats,
      ),
      mealsCount: meals.length,
    );
  }

  // Quick access methods
  String get userName =>
      authController.user?.displayName ??
      authController.user?.email?.split('@').first ??
      'User';

  bool get hasNutritionData => nutritionController.todayMeals.isNotEmpty;

  int get todayMealsCount => nutritionController.todayMeals.length;
}

// models
class TodayIntakeModel {
  final double totalCalories;
  final NutritionSummary totalNutrition;
  final int mealsCount;

  TodayIntakeModel({
    required this.totalCalories,
    required this.totalNutrition,
    required this.mealsCount,
  });
}

class NutritionSummary {
  final double? proteins100g;
  final double? carbohydrates100g;
  final double? fat100g;

  NutritionSummary({this.proteins100g, this.carbohydrates100g, this.fat100g});
}
