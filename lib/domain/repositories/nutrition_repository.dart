import '../entities/daily_intake.dart';
import '../entities/meal_entry.dart';
import '../../core/utils/result.dart';

abstract class NutritionRepository {
  Future<Result<DailyIntake>> getDailyIntake(String userId, DateTime date);
  Future<Result<List<DailyIntake>>> getWeeklyIntake(
    String userId,
    DateTime startDate,
  );
  Future<Result<List<DailyIntake>>> getMonthlyIntake(
    String userId,
    DateTime month,
  );
  Stream<DailyIntake> watchDailyIntake(String userId, DateTime date);
  Future<Result<void>> saveDailyIntake(DailyIntake intake);
  Future<Result<void>> addMeal(String userId, DateTime date, MealEntry meal);
  Future<Result<void>> updateMeal(
    String userId,
    DateTime date,
    int mealIndex,
    MealEntry meal,
  );
  Future<Result<void>> deleteMeal(String userId, DateTime date, String mealId);
  Future<Result<void>> updateWaterIntake(
    String userId,
    DateTime date,
    double glasses,
  );
  Future<Result<void>> updateWeight(
    String userId,
    DateTime date,
    double weight,
  );
  Future<Result<void>> clearAllMeals(String userId);
}
