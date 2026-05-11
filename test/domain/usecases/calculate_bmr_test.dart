import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_check/domain/usecases/calculate_bmr.dart';
import 'package:nutri_check/domain/entities/user_profile.dart';

void main() {
  late CalculateBMR calculator;

  setUp(() {
    calculator = CalculateBMR();
  });

  group('CalculateBMR', () {
    test('calculates BMR for 70kg 175cm 25yo male', () {
      final profile = UserProfile(
        id: '1',
        email: 'test@test.com',
        currentWeight: 70,
        height: 175,
        age: 25,
        gender: Gender.male,
      );
      final bmr = calculator.execute(profile);
      expect(bmr, closeTo(1724.0, 1.0));
    });

    test('calculates BMR for 60kg 165cm 25yo female', () {
      final profile = UserProfile(
        id: '1',
        email: 'test@test.com',
        currentWeight: 60,
        height: 165,
        age: 25,
        gender: Gender.female,
      );
      final bmr = calculator.execute(profile);
      expect(bmr, closeTo(1405.3, 1.0));
    });

    test('TDEE multiplies BMR by activity factor', () {
      final profile = UserProfile(
        id: '1',
        email: 'test@test.com',
        currentWeight: 70,
        height: 175,
        age: 25,
        gender: Gender.male,
      );
      final tdee = calculator.calculateTDEE(profile, activityMultiplier: 1.55);
      final bmr = calculator.execute(profile);
      expect(tdee, closeTo(bmr * 1.55, 1.0));
    });

    test('macro split for maintain goal matches TDEE', () {
      final macros = calculator.calculateMacroSplit(2000, goal: 'maintain');
      expect(macros['calories'], equals(2000));
      expect(macros['protein']!, greaterThan(0));
      expect(macros['carbs']!, greaterThan(0));
      expect(macros['fat']!, greaterThan(0));
    });

    test('macro split for lose goal reduces calories by 500', () {
      final macros = calculator.calculateMacroSplit(2000, goal: 'lose');
      expect(macros['calories'], equals(1500));
    });

    test('macro split for gain goal increases calories by 500', () {
      final macros = calculator.calculateMacroSplit(2000, goal: 'gain');
      expect(macros['calories'], equals(2500));
    });
  });
}
