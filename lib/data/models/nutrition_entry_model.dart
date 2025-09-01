import 'package:cloud_firestore/cloud_firestore.dart';

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
      date: DateTime.parse(map['date']),
      meals: List<MealEntryModel>.from(
        map['meals']?.map((meal) => MealEntryModel.fromMap(meal)) ?? [],
      ),
      waterIntake: map['waterIntake']?.toDouble() ?? 0,
      stepsCount: map['stepsCount'] ?? 0,
      weight: map['weight']?.toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  factory NutritionEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NutritionEntryModel.fromMap(data);
  }
}

class MealEntryModel {
  final String id;
  final String name;
  final String type;
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
      'type': type,
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
      type: map['type'] ?? 'meal',
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
}
