import 'package:flutter/material.dart';
import 'package:nutri_check/core/constants/app_colors.dart';
import 'package:nutri_check/domain/entities/meal_entry.dart';

class MealTypeHelpers {
  static Color getColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return AppColors.warning;
      case MealType.lunch:
        return AppColors.success;
      case MealType.dinner:
        return AppColors.info;
      case MealType.snack:
        return AppColors.secondary;
    }
  }

  static IconData getIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.wb_sunny_outlined;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snack:
        return Icons.local_cafe;
    }
  }

  static String getLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}
