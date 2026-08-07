import 'package:flutter_test/flutter_test.dart';
import 'package:nutraflow/core/utils/calorie_calculator.dart';
import 'package:nutraflow/features/onboarding/models/onboarding_data.dart';

void main() {
  group('CalorieCalculator.calculateBMR', () {
    test('Mifflin-St Jeor for male', () {
      final bmr = CalorieCalculator.calculateBMR(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        gender: 'male',
      );
      expect(bmr, closeTo(1648.75, 0.01));
    });

    test('Mifflin-St Jeor for female', () {
      final bmr = CalorieCalculator.calculateBMR(
        weightKg: 60,
        heightCm: 165,
        age: 25,
        gender: 'female',
      );
      expect(bmr, closeTo(1345.25, 0.01));
    });
  });

  group('CalorieCalculator.calculateTDEE', () {
    test('scales BMR by the activity factor', () {
      expect(
        CalorieCalculator.calculateTDEE(
          bmr: 1600,
          activityLevel: ActivityLevel.sedentary,
        ),
        closeTo(1920, 0.01),
      );
      expect(
        CalorieCalculator.calculateTDEE(
          bmr: 1600,
          activityLevel: ActivityLevel.veryActive,
        ),
        closeTo(2760, 0.01),
      );
    });
  });

  group('CalorieCalculator.calculateDailyCalories', () {
    test('applies a deficit for weight loss and surplus for muscle gain', () {
      expect(
        CalorieCalculator.calculateDailyCalories(
          tdee: 2200,
          goal: FitnessGoal.loseWeight,
        ),
        2200 - 500,
      );
      expect(
        CalorieCalculator.calculateDailyCalories(
          tdee: 2200,
          goal: FitnessGoal.gainMuscle,
        ),
        2200 + 300,
      );
      expect(
        CalorieCalculator.calculateDailyCalories(
          tdee: 2200,
          goal: FitnessGoal.maintain,
        ),
        2200,
      );
    });
  });

  group('CalorieCalculator.calculateMacros', () {
    test('splits calories 30/45/25 into protein/carbs/fat grams', () {
      final macros = CalorieCalculator.calculateMacros(2000);
      expect(macros.proteinG, 150); // 2000 * 0.30 / 4
      expect(macros.carbsG, 225); // 2000 * 0.45 / 4
      expect(macros.fatG, 56); // 2000 * 0.25 / 9, rounded
    });
  });

  group('CalorieCalculator.calculateNutritionScore', () {
    test('scores a perfectly on-target day near 100', () {
      final score = CalorieCalculator.calculateNutritionScore(
        consumedCalories: 2000,
        targetCalories: 2000,
        consumedProtein: 150,
        targetProtein: 150,
        consumedCarbs: 225,
        targetCarbs: 225,
        consumedFat: 65,
        targetFat: 65,
      );
      expect(score, greaterThanOrEqualTo(95));
    });

    test('clamps into the 0-100 range for wildly off-target days', () {
      final score = CalorieCalculator.calculateNutritionScore(
        consumedCalories: 6000,
        targetCalories: 2000,
        consumedProtein: 0,
        targetProtein: 150,
        consumedCarbs: 800,
        targetCarbs: 225,
        consumedFat: 300,
        targetFat: 65,
      );
      expect(score, inInclusiveRange(0, 100));
    });
  });
}
