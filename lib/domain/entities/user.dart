class UserProfile {
  String? id;
  String? name;
  String? email;
  String? bio;
  double currentWeight;
  double targetWeight;
  double height;
  int age;
  String gender;
  String? profileImageUrl;
  DateTime? joinDate;
  Map<String, dynamic>? preferences;

  UserProfile({
    this.id,
    this.name,
    this.email,
    this.bio,
    this.currentWeight = 70.0,
    this.targetWeight = 65.0,
    this.height = 175.0,
    this.age = 25,
    this.gender = 'Male',
    this.profileImageUrl,
    this.joinDate,
    this.preferences,
  });

  // BMI calculation
  double get bmi {
    if (height > 0 && currentWeight > 0) {
      final heightInMeters = height / 100;
      return currentWeight / (heightInMeters * heightInMeters);
    }
    return 0.0;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      bio: json['bio'],
      currentWeight: (json['currentWeight'] ?? 70.0).toDouble(),
      targetWeight: (json['targetWeight'] ?? 65.0).toDouble(),
      height: (json['height'] ?? 175.0).toDouble(),
      age: json['age'] ?? 25,
      gender: json['gender'] ?? 'Male',
      profileImageUrl: json['profileImageUrl'],
      joinDate: json['joinDate'] != null
          ? DateTime.parse(json['joinDate'])
          : null,
      preferences: json['preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'height': height,
      'age': age,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'joinDate': joinDate?.toIso8601String(),
      'preferences': preferences,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    double? currentWeight,
    double? targetWeight,
    double? height,
    int? age,
    String? gender,
    String? profileImageUrl,
    DateTime? joinDate,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinDate: joinDate ?? this.joinDate,
      preferences: preferences ?? this.preferences,
    );
  }
}
