import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nutrition Goals
  final double calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final double waterGoal;
  final int stepsGoal;

  // Personal Info
  final double? currentWeight;
  final double? targetWeight;
  final double? height;
  final int? age;
  final String? gender;
  final String? activityLevel;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.calorieGoal = 2000,
    this.proteinGoal = 150,
    this.carbGoal = 250,
    this.fatGoal = 65,
    this.waterGoal = 8,
    this.stepsGoal = 10000,
    this.currentWeight,
    this.targetWeight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbGoal': carbGoal,
      'fatGoal': fatGoal,
      'waterGoal': waterGoal,
      'stepsGoal': stepsGoal,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'height': height,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      calorieGoal: map['calorieGoal']?.toDouble() ?? 2000,
      proteinGoal: map['proteinGoal']?.toDouble() ?? 150,
      carbGoal: map['carbGoal']?.toDouble() ?? 250,
      fatGoal: map['fatGoal']?.toDouble() ?? 65,
      waterGoal: map['waterGoal']?.toDouble() ?? 8,
      stepsGoal: map['stepsGoal'] ?? 10000,
      currentWeight: map['currentWeight']?.toDouble(),
      targetWeight: map['targetWeight']?.toDouble(),
      height: map['height']?.toDouble(),
      age: map['age'],
      gender: map['gender'],
      activityLevel: map['activityLevel'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    double? calorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    double? waterGoal,
    int? stepsGoal,
    double? currentWeight,
    double? targetWeight,
    double? height,
    int? age,
    String? gender,
    String? activityLevel,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}
