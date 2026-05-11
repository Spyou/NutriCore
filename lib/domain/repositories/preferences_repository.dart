import '../../core/utils/result.dart';
import '../../core/config/app_config.dart';

class UserPreferences {
  final double calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final double waterGoal;
  final int stepsGoal;
  final List<String> recentSearches;
  final List<Map<String, dynamic>> favoriteMeals;
  final Map<String, dynamic> settings;

  const UserPreferences({
    this.calorieGoal = AppConfig.defaultCalorieGoal,
    this.proteinGoal = AppConfig.defaultProteinGoal,
    this.carbGoal = AppConfig.defaultCarbGoal,
    this.fatGoal = AppConfig.defaultFatGoal,
    this.waterGoal = AppConfig.defaultWaterGoal,
    this.stepsGoal = AppConfig.defaultStepsGoal,
    this.recentSearches = const [],
    this.favoriteMeals = const [],
    this.settings = const {},
  });

  UserPreferences copyWith({
    double? calorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    double? waterGoal,
    int? stepsGoal,
    List<String>? recentSearches,
    List<Map<String, dynamic>>? favoriteMeals,
    Map<String, dynamic>? settings,
  }) {
    return UserPreferences(
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      recentSearches: recentSearches ?? this.recentSearches,
      favoriteMeals: favoriteMeals ?? this.favoriteMeals,
      settings: settings ?? this.settings,
    );
  }
}

abstract class PreferencesRepository {
  Future<Result<UserPreferences>> getPreferences(String uid);
  Future<Result<void>> savePreferences(String uid, UserPreferences prefs);
  Future<Result<void>> updateGoals(
    String uid, {
    double? calorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    double? waterGoal,
    int? stepsGoal,
  });
  Future<Result<void>> addRecentSearch(String uid, String query);
  Future<Result<void>> clearRecentSearches(String uid);
  Future<Result<void>> toggleFavorite(String uid, Map<String, dynamic> meal);
  Future<Result<List<Map<String, dynamic>>>> getFavorites(String uid);
}
