import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/config/app_config.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;

  final double calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final double waterGoal;
  final int stepsGoal;

  final double? currentWeight;
  final double? targetWeight;
  final double? height;
  final int? age;
  final Gender gender;
  final String? activityLevel;

  /// True once the user has completed the onboarding flow. New accounts
  /// start with `false` and remain there until the onboarding's final
  /// step persists. Source of truth — the AuthController checks this on
  /// every auth state change to decide between MainPage and OnboardingPage.
  final bool onboardingComplete;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.calorieGoal = AppConfig.defaultCalorieGoal,
    this.proteinGoal = AppConfig.defaultProteinGoal,
    this.carbGoal = AppConfig.defaultCarbGoal,
    this.fatGoal = AppConfig.defaultFatGoal,
    this.waterGoal = AppConfig.defaultWaterGoal,
    this.stepsGoal = AppConfig.defaultStepsGoal,
    this.currentWeight,
    this.targetWeight,
    this.height,
    this.age,
    this.gender = Gender.male,
    this.activityLevel,
    this.onboardingComplete = false,
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
      'gender': gender.name,
      'activityLevel': activityLevel,
      'onboardingComplete': onboardingComplete,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      calorieGoal:
          map['calorieGoal']?.toDouble() ?? AppConfig.defaultCalorieGoal,
      proteinGoal:
          map['proteinGoal']?.toDouble() ?? AppConfig.defaultProteinGoal,
      carbGoal: map['carbGoal']?.toDouble() ?? AppConfig.defaultCarbGoal,
      fatGoal: map['fatGoal']?.toDouble() ?? AppConfig.defaultFatGoal,
      waterGoal: map['waterGoal']?.toDouble() ?? AppConfig.defaultWaterGoal,
      stepsGoal: _parseIntSafe(map['stepsGoal']) ?? AppConfig.defaultStepsGoal,
      currentWeight: map['currentWeight']?.toDouble(),
      targetWeight: map['targetWeight']?.toDouble(),
      height: map['height']?.toDouble(),
      age: map['age'] is int
          ? map['age']
          : (map['age'] is double ? (map['age'] as double).toInt() : null),
      gender: _parseGender(map['gender']),
      activityLevel: map['activityLevel'],
      onboardingComplete: map['onboardingComplete'] == true,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Document data was null');
    }
    return UserModel.fromMap(data as Map<String, dynamic>);
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
    Gender? gender,
    String? activityLevel,
    bool? onboardingComplete,
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
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  UserProfile toDomain() {
    return UserProfile(
      id: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      currentWeight: currentWeight ?? AppConfig.defaultWeight,
      targetWeight: targetWeight ?? AppConfig.defaultTargetWeight,
      height: height ?? AppConfig.defaultHeight,
      age: age ?? AppConfig.defaultAge,
      gender: gender,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserModel.fromDomain(UserProfile profile) {
    return UserModel(
      uid: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      photoURL: profile.photoURL,
      currentWeight: profile.currentWeight,
      targetWeight: profile.targetWeight,
      height: profile.height,
      age: profile.age,
      gender: profile.gender,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
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

int? _parseIntSafe(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return null;
}

Gender _parseGender(dynamic value) {
  if (value is String) {
    return Gender.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Gender.male,
    );
  }
  return Gender.male;
}
