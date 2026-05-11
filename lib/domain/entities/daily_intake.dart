import 'package:equatable/equatable.dart';
import 'meal_entry.dart';

class DailyIntake extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final List<MealEntry> meals;
  final double waterIntake;
  final int stepsCount;
  final double weight;

  const DailyIntake({
    required this.id,
    required this.userId,
    required this.date,
    this.meals = const [],
    this.waterIntake = 0,
    this.stepsCount = 0,
    this.weight = 0,
  });

  double get totalCalories => meals.fold(0.0, (sum, m) => sum + m.calories);

  double get totalProteins => meals.fold(0.0, (sum, m) => sum + m.proteins);

  double get totalCarbs => meals.fold(0.0, (sum, m) => sum + m.carbs);

  double get totalFats => meals.fold(0.0, (sum, m) => sum + m.fat);

  DailyIntake copyWith({
    String? userId,
    DateTime? date,
    List<MealEntry>? meals,
    double? waterIntake,
    int? stepsCount,
    double? weight,
  }) {
    return DailyIntake(
      id: id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      waterIntake: waterIntake ?? this.waterIntake,
      stepsCount: stepsCount ?? this.stepsCount,
      weight: weight ?? this.weight,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    date,
    meals,
    waterIntake,
    stepsCount,
    weight,
  ];
}
