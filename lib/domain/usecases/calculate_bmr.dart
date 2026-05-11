import '../entities/user_profile.dart';

class CalculateBMR {
  double execute(UserProfile profile) {
    if (profile.gender == Gender.male) {
      return 88.362 +
          (13.397 * profile.currentWeight) +
          (4.799 * profile.height) -
          (5.677 * profile.age);
    } else {
      return 447.593 +
          (9.247 * profile.currentWeight) +
          (3.098 * profile.height) -
          (4.330 * profile.age);
    }
  }

  double calculateTDEE(
    UserProfile profile, {
    double activityMultiplier = 1.55,
  }) {
    return execute(profile) * activityMultiplier;
  }

  Map<String, double> calculateMacroSplit(
    double tdee, {
    String goal = 'maintain',
  }) {
    double calorieTarget;
    switch (goal) {
      case 'lose':
        calorieTarget = tdee - 500;
      case 'gain':
        calorieTarget = tdee + 500;
      default:
        calorieTarget = tdee;
    }

    return {
      'calories': calorieTarget,
      'protein': (calorieTarget * 0.30) / 4,
      'carbs': (calorieTarget * 0.40) / 4,
      'fat': (calorieTarget * 0.30) / 9,
      'water': 8.0,
    };
  }
}
