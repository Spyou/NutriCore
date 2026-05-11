import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_check/domain/entities/meal_entry.dart';

void main() {
  group('MealType', () {
    test('fromString returns correct enum for known values', () {
      expect(MealTypeX.fromString('breakfast'), equals(MealType.breakfast));
      expect(MealTypeX.fromString('lunch'), equals(MealType.lunch));
      expect(MealTypeX.fromString('dinner'), equals(MealType.dinner));
      expect(MealTypeX.fromString('snack'), equals(MealType.snack));
    });

    test('fromString returns snack for unknown value', () {
      expect(MealTypeX.fromString('meal'), equals(MealType.snack));
      expect(MealTypeX.fromString('unknown'), equals(MealType.snack));
    });

    test('fromString is case insensitive', () {
      expect(MealTypeX.fromString('Breakfast'), equals(MealType.breakfast));
      expect(MealTypeX.fromString('LUNCH'), equals(MealType.lunch));
    });

    test('label returns correct string', () {
      expect(MealType.breakfast.label, equals('Breakfast'));
      expect(MealType.lunch.label, equals('Lunch'));
      expect(MealType.dinner.label, equals('Dinner'));
      expect(MealType.snack.label, equals('Snack'));
    });
  });

  group('MealEntry', () {
    final meal = MealEntry(
      id: '1',
      name: 'Test Meal',
      type: MealType.lunch,
      calories: 500,
      proteins: 30,
      carbs: 50,
      fat: 15,
    );

    test('copyWith creates new instance with updated fields', () {
      final updated = meal.copyWith(calories: 600, name: 'Updated');
      expect(updated.calories, equals(600));
      expect(updated.name, equals('Updated'));
      expect(updated.id, equals(meal.id));
      expect(updated.proteins, equals(meal.proteins));
    });

    test('equality works correctly', () {
      final same = MealEntry(
        id: '1',
        name: 'Test Meal',
        type: MealType.lunch,
        calories: 500,
        proteins: 30,
        carbs: 50,
        fat: 15,
      );
      expect(meal, equals(same));
    });

    test('different id produces inequality', () {
      final other = MealEntry(
        id: '2',
        name: 'Test Meal',
        type: MealType.lunch,
        calories: 500,
        proteins: 30,
        carbs: 50,
        fat: 15,
      );
      expect(meal, isNot(equals(other)));
    });
  });
}
