import 'package:equatable/equatable.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MealType.snack,
    );
  }
}

class MealEntry extends Equatable {
  final String id;
  final String name;
  final MealType type;
  final double calories;
  final double proteins;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final String? notes;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime timestamp;

  MealEntry({
    required this.id,
    required this.name,
    required this.type,
    this.calories = 0,
    this.proteins = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.notes,
    this.imageUrl,
    this.isFavorite = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  MealEntry copyWith({
    String? name,
    MealType? type,
    double? calories,
    double? proteins,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    String? notes,
    String? imageUrl,
    bool? isFavorite,
    DateTime? timestamp,
  }) {
    return MealEntry(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, name, type, calories, proteins, carbs, fat];
}
