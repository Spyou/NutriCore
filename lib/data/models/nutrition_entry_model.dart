import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/daily_intake.dart';

class NutritionEntryModel {
  final String id;
  final String userId;
  final DateTime date;
  final List<MealEntryModel> meals;
  final double waterIntake;
  final int stepsCount;
  final double? weight;
  final DateTime createdAt;
  final DateTime updatedAt;

  NutritionEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
    this.waterIntake = 0,
    this.stepsCount = 0,
    this.weight,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'waterIntake': waterIntake,
      'stepsCount': stepsCount,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NutritionEntryModel.fromMap(Map<String, dynamic> map) {
    return NutritionEntryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: _parseDateTime(map['date']),
      meals: List<MealEntryModel>.from(
        map['meals']?.map((meal) => MealEntryModel.fromMap(meal)) ?? [],
      ),
      waterIntake: map['waterIntake']?.toDouble() ?? 0,
      stepsCount: map['stepsCount'] is int
          ? map['stepsCount'] as int
          : (map['stepsCount'] is double
                ? (map['stepsCount'] as double).toInt()
                : 0),
      weight: map['weight']?.toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory NutritionEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Document data was null');
    }
    return NutritionEntryModel.fromMap(data as Map<String, dynamic>);
  }

  DailyIntake toDomain() {
    return DailyIntake(
      id: id,
      userId: userId,
      date: date,
      meals: meals.map((m) => m.toDomain()).toList(),
      waterIntake: waterIntake,
      stepsCount: stepsCount,
      weight: weight ?? 0,
    );
  }

  factory NutritionEntryModel.fromDomain(DailyIntake intake) {
    return NutritionEntryModel(
      id: intake.id,
      userId: intake.userId,
      date: intake.date,
      meals: intake.meals.map((m) => MealEntryModel.fromDomain(m)).toList(),
      waterIntake: intake.waterIntake,
      stepsCount: intake.stepsCount,
      weight: intake.weight,
      createdAt: intake.date,
      updatedAt: DateTime.now(),
    );
  }
}

class MealEntryModel {
  final String id;
  final String name;
  final MealType type;
  final String time;
  final double calories;
  final double proteins;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final String? notes;
  final String? imageUrl;
  final bool favorite;

  MealEntryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.notes,
    this.imageUrl,
    this.favorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'time': time,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'notes': notes,
      'imageUrl': imageUrl,
      'favorite': favorite,
    };
  }

  factory MealEntryModel.fromMap(Map<String, dynamic> map) {
    return MealEntryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: MealTypeX.fromString(map['type'] ?? 'snack'),
      time: map['time'] ?? '',
      calories: map['calories']?.toDouble() ?? 0,
      proteins: map['proteins']?.toDouble() ?? 0,
      carbs: map['carbs']?.toDouble() ?? 0,
      fat: map['fat']?.toDouble() ?? 0,
      fiber: map['fiber']?.toDouble() ?? 0,
      sugar: map['sugar']?.toDouble() ?? 0,
      sodium: map['sodium']?.toDouble() ?? 0,
      notes: map['notes'],
      imageUrl: map['imageUrl'],
      favorite: map['favorite'] ?? false,
    );
  }

  MealEntry toDomain() {
    return MealEntry(
      id: id,
      name: name,
      type: type,
      calories: calories,
      proteins: proteins,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      notes: notes,
      imageUrl: imageUrl,
      isFavorite: favorite,
      timestamp: _parseDateTime(time),
    );
  }

  factory MealEntryModel.fromDomain(MealEntry meal) {
    return MealEntryModel(
      id: meal.id,
      name: meal.name,
      type: meal.type,
      time: meal.timestamp.toIso8601String(),
      calories: meal.calories,
      proteins: meal.proteins,
      carbs: meal.carbs,
      fat: meal.fat,
      fiber: meal.fiber,
      sugar: meal.sugar,
      sodium: meal.sodium,
      notes: meal.notes,
      imageUrl: meal.imageUrl,
      favorite: meal.isFavorite,
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  if (value is Timestamp) return value.toDate();
  return DateTime.now();
}
