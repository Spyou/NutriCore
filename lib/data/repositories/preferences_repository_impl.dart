import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/firebase_datasource.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final FirebaseDataSource _firebaseDataSource;

  PreferencesRepositoryImpl({required FirebaseDataSource firebaseDataSource})
    : _firebaseDataSource = firebaseDataSource;

  @override
  Future<Result<UserPreferences>> getPreferences(String uid) async {
    try {
      final doc = await _firebaseDataSource.getDocument(
        AppConfig.preferencesCollection,
        uid,
      );
      if (!doc.exists) {
        return const Result.success(UserPreferences());
      }
      final data = doc.data() as Map<String, dynamic>;
      return Result.success(
        UserPreferences(
          calorieGoal:
              data['calorieGoal']?.toDouble() ?? AppConfig.defaultCalorieGoal,
          proteinGoal:
              data['proteinGoal']?.toDouble() ?? AppConfig.defaultProteinGoal,
          carbGoal: data['carbGoal']?.toDouble() ?? AppConfig.defaultCarbGoal,
          fatGoal: data['fatGoal']?.toDouble() ?? AppConfig.defaultFatGoal,
          waterGoal:
              data['waterGoal']?.toDouble() ?? AppConfig.defaultWaterGoal,
          stepsGoal: data['stepsGoal'] ?? AppConfig.defaultStepsGoal,
          recentSearches: List<String>.from(data['recentSearches'] ?? []),
          favoriteMeals: List<Map<String, dynamic>>.from(
            data['favoriteMeals'] ?? [],
          ),
          settings: Map<String, dynamic>.from(data['settings'] ?? {}),
        ),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> savePreferences(
    String uid,
    UserPreferences prefs,
  ) async {
    try {
      await _firebaseDataSource.setDocument(
        AppConfig.preferencesCollection,
        uid,
        _toMap(prefs),
      );
      return const Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateGoals(
    String uid, {
    double? calorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    double? waterGoal,
    int? stepsGoal,
  }) async {
    try {
      final currentResult = await getPreferences(uid);
      if (currentResult.isFailure) {
        return Result.failure(currentResult.failure);
      }
      final updated = currentResult.value.copyWith(
        calorieGoal: calorieGoal,
        proteinGoal: proteinGoal,
        carbGoal: carbGoal,
        fatGoal: fatGoal,
        waterGoal: waterGoal,
        stepsGoal: stepsGoal,
      );
      return savePreferences(uid, updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> addRecentSearch(String uid, String query) async {
    try {
      final currentResult = await getPreferences(uid);
      final current = currentResult.isSuccess
          ? currentResult.value
          : const UserPreferences();
      final updatedSearches = [
        query,
        ...current.recentSearches.where((s) => s != query),
      ].take(10).toList();
      final updated = current.copyWith(recentSearches: updatedSearches);
      return savePreferences(uid, updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> clearRecentSearches(String uid) async {
    try {
      final currentResult = await getPreferences(uid);
      final current = currentResult.isSuccess
          ? currentResult.value
          : const UserPreferences();
      final updated = current.copyWith(recentSearches: []);
      return savePreferences(uid, updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleFavorite(
    String uid,
    Map<String, dynamic> meal,
  ) async {
    try {
      final currentResult = await getPreferences(uid);
      final current = currentResult.isSuccess
          ? currentResult.value
          : const UserPreferences();
      final mealId = meal['id'];
      final exists = current.favoriteMeals.any((m) => m['id'] == mealId);
      final updatedFavorites = exists
          ? current.favoriteMeals.where((m) => m['id'] != mealId).toList()
          : [...current.favoriteMeals, meal];
      final updated = current.copyWith(favoriteMeals: updatedFavorites);
      return savePreferences(uid, updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getFavorites(String uid) async {
    try {
      final prefsResult = await getPreferences(uid);
      if (prefsResult.isFailure) {
        return Result.failure(prefsResult.failure);
      }
      return Result.success(prefsResult.value.favoriteMeals);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Map<String, dynamic> _toMap(UserPreferences prefs) {
    return {
      'calorieGoal': prefs.calorieGoal,
      'proteinGoal': prefs.proteinGoal,
      'carbGoal': prefs.carbGoal,
      'fatGoal': prefs.fatGoal,
      'waterGoal': prefs.waterGoal,
      'stepsGoal': prefs.stepsGoal,
      'recentSearches': prefs.recentSearches,
      'favoriteMeals': prefs.favoriteMeals,
      'settings': prefs.settings,
    };
  }
}
