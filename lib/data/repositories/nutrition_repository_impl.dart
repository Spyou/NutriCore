import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/daily_intake.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../datasources/firebase_datasource.dart';
import '../mappers/nutrition_mapper.dart';
import '../models/nutrition_entry_model.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final FirebaseDataSource _firebaseDataSource;

  NutritionRepositoryImpl({required FirebaseDataSource firebaseDataSource})
    : _firebaseDataSource = firebaseDataSource;

  String _docId(String userId, DateTime date) =>
      '${userId}_${_formatDate(date)}';

  String _formatDate(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  @override
  Future<Result<DailyIntake>> getDailyIntake(
    String userId,
    DateTime date,
  ) async {
    try {
      final docId = _docId(userId, date);
      final doc = await _firebaseDataSource.getDocument(
        AppConfig.nutritionCollection,
        docId,
      );
      if (!doc.exists) {
        return Result.failure(
          NotFoundFailure(message: 'Daily intake not found for $docId'),
        );
      }
      final model = NutritionEntryModel.fromFirestore(doc);
      return Result.success(NutritionMapper.toDomain(model));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<DailyIntake>>> getWeeklyIntake(
    String userId,
    DateTime startDate,
  ) async {
    try {
      final docs = await _firebaseDataSource.queryDocuments(
        AppConfig.nutritionCollection,
        field: 'userId',
        isEqualTo: userId,
        orderBy: 'date',
      );
      final intakes = docs.docs
          .map(
            (doc) => NutritionMapper.toDomain(
              NutritionEntryModel.fromFirestore(doc),
            ),
          )
          .toList();
      return Result.success(intakes);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<DailyIntake>>> getMonthlyIntake(
    String userId,
    DateTime month,
  ) async {
    try {
      final docs = await _firebaseDataSource.queryDocuments(
        AppConfig.nutritionCollection,
        field: 'userId',
        isEqualTo: userId,
        orderBy: 'date',
      );
      final intakes = docs.docs
          .map(
            (doc) => NutritionMapper.toDomain(
              NutritionEntryModel.fromFirestore(doc),
            ),
          )
          .toList();
      return Result.success(intakes);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<DailyIntake> watchDailyIntake(String userId, DateTime date) {
    final docId = _docId(userId, date);
    return _firebaseDataSource
        .watchDocument(AppConfig.nutritionCollection, docId)
        .map((doc) {
          if (!doc.exists) {
            return DailyIntake(id: docId, userId: userId, date: date);
          }
          final model = NutritionEntryModel.fromFirestore(doc);
          return NutritionMapper.toDomain(model);
        });
  }

  @override
  Future<Result<void>> saveDailyIntake(DailyIntake intake) async {
    try {
      final model = NutritionMapper.toModel(intake);
      await _firebaseDataSource.setDocument(
        AppConfig.nutritionCollection,
        model.id,
        model.toMap(),
      );
      return const Result.success(null);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> addMeal(
    String userId,
    DateTime date,
    MealEntry meal,
  ) async {
    try {
      final currentResult = await getDailyIntake(userId, date);
      final current = currentResult.isSuccess
          ? currentResult.value
          : DailyIntake(id: _docId(userId, date), userId: userId, date: date);
      final updated = current.copyWith(meals: [...current.meals, meal]);
      return saveDailyIntake(updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateMeal(
    String userId,
    DateTime date,
    int mealIndex,
    MealEntry meal,
  ) async {
    try {
      final currentResult = await getDailyIntake(userId, date);
      if (currentResult.isFailure) {
        return Result.failure(currentResult.failure);
      }
      final current = currentResult.value;
      if (mealIndex < 0 || mealIndex >= current.meals.length) {
        return const Result.failure(
          ServerFailure(message: 'Invalid meal index'),
        );
      }
      final updatedMeals = List<MealEntry>.from(current.meals);
      updatedMeals[mealIndex] = meal;
      final updated = current.copyWith(meals: updatedMeals);
      return saveDailyIntake(updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMeal(
    String userId,
    DateTime date,
    String mealId,
  ) async {
    try {
      final currentResult = await getDailyIntake(userId, date);
      if (currentResult.isFailure) {
        return Result.failure(currentResult.failure);
      }
      final current = currentResult.value;
      final updatedMeals = current.meals.where((m) => m.id != mealId).toList();
      final updated = current.copyWith(meals: updatedMeals);
      return saveDailyIntake(updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateWaterIntake(
    String userId,
    DateTime date,
    double glasses,
  ) async {
    try {
      final currentResult = await getDailyIntake(userId, date);
      final current = currentResult.isSuccess
          ? currentResult.value
          : DailyIntake(id: _docId(userId, date), userId: userId, date: date);
      final updated = current.copyWith(waterIntake: glasses);
      return saveDailyIntake(updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateWeight(
    String userId,
    DateTime date,
    double weight,
  ) async {
    try {
      final currentResult = await getDailyIntake(userId, date);
      final current = currentResult.isSuccess
          ? currentResult.value
          : DailyIntake(id: _docId(userId, date), userId: userId, date: date);
      final updated = current.copyWith(weight: weight);
      return saveDailyIntake(updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> clearAllMeals(String userId) async {
    try {
      final date = DateTime.now();
      final currentResult = await getDailyIntake(userId, date);
      final current = currentResult.isSuccess
          ? currentResult.value
          : DailyIntake(id: _docId(userId, date), userId: userId, date: date);
      final updated = current.copyWith(meals: []);
      return saveDailyIntake(updated);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
