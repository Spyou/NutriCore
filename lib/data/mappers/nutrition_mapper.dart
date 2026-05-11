import '../models/nutrition_entry_model.dart';
import '../../domain/entities/daily_intake.dart';

class NutritionMapper {
  static DailyIntake toDomain(NutritionEntryModel model) => model.toDomain();

  static NutritionEntryModel toModel(DailyIntake intake) =>
      NutritionEntryModel.fromDomain(intake);
}
