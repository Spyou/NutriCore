import 'package:equatable/equatable.dart';
import 'package:nutri_check/core/config/app_config.dart';

enum Gender { male, female, other }

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final double currentWeight;
  final double targetWeight;
  final double height;
  final int age;
  final Gender gender;
  final String? profileImageUrl;
  final DateTime? joinDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    this.currentWeight = AppConfig.defaultWeight,
    this.targetWeight = AppConfig.defaultTargetWeight,
    this.height = AppConfig.defaultHeight,
    this.age = AppConfig.defaultAge,
    this.gender = Gender.male,
    this.profileImageUrl,
    this.joinDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get bmi {
    if (height <= 0 || currentWeight <= 0) return 0;
    final heightM = height / 100;
    return currentWeight / (heightM * heightM);
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? bio,
    double? currentWeight,
    double? targetWeight,
    double? height,
    int? age,
    Gender? gender,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinDate: joinDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    currentWeight,
    targetWeight,
    height,
    age,
    gender,
  ];
}
