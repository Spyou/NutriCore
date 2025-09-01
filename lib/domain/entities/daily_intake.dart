import 'product.dart';

class DailyIntake {
  final String id;
  final DateTime date;
  final List<MealEntry> meals;
  final Nutriments totalNutrition;
  final double waterIntake;
  final int steps;

  DailyIntake({
    required this.id,
    required this.date,
    required this.meals,
    required this.totalNutrition,
    this.waterIntake = 0,
    this.steps = 0,
  });

  double get totalCalories => totalNutrition.energyKcal100g ?? 0;
}

class MealEntry {
  final String id;
  final String name;
  final MealType type;
  final List<FoodEntry> foods;
  final DateTime timestamp;

  MealEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.foods,
    required this.timestamp,
  });
}

class FoodEntry {
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final Nutriments nutrition;

  FoodEntry({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.nutrition,
  });
}

enum MealType { breakfast, lunch, dinner, snack }
