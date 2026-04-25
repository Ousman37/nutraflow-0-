import '../../features/onboarding/models/onboarding_data.dart';

class CalorieCalculator {
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    }
    return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  }

  static double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    const factors = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.lightlyActive: 1.375,
      ActivityLevel.moderatelyActive: 1.55,
      ActivityLevel.veryActive: 1.725,
      ActivityLevel.extremelyActive: 1.9,
    };
    return bmr * (factors[activityLevel] ?? 1.2);
  }

  static double calculateDailyCalories({
    required double tdee,
    required FitnessGoal goal,
  }) {
    switch (goal) {
      case FitnessGoal.loseWeight:
        return tdee - 500;
      case FitnessGoal.gainMuscle:
        return tdee + 300;
      case FitnessGoal.maintain:
      case FitnessGoal.improveHealth:
        return tdee;
    }
  }

  static MacroTargets calculateMacros(double dailyCalories) {
    // Protein 30%, Carbs 45%, Fat 25%
    final protein = (dailyCalories * 0.30) / 4;
    final carbs = (dailyCalories * 0.45) / 4;
    final fat = (dailyCalories * 0.25) / 9;
    return MacroTargets(
      proteinG: protein.round(),
      carbsG: carbs.round(),
      fatG: fat.round(),
    );
  }

  static int calculateNutritionScore({
    required double consumedCalories,
    required double targetCalories,
    required double consumedProtein,
    required double targetProtein,
    required double consumedCarbs,
    required double targetCarbs,
    required double consumedFat,
    required double targetFat,
  }) {
    double score = 0;

    // Calorie adherence (40 points)
    final calRatio = consumedCalories / targetCalories;
    if (calRatio >= 0.85 && calRatio <= 1.1) {
      score += 40;
    } else if (calRatio >= 0.75 && calRatio <= 1.2) {
      score += 25;
    } else {
      score += 10;
    }

    // Protein (30 points)
    final protRatio = consumedProtein / targetProtein;
    score += (protRatio.clamp(0.0, 1.0) * 30);

    // Carbs (20 points)
    final carbRatio = consumedCarbs / targetCarbs;
    if (carbRatio >= 0.8 && carbRatio <= 1.1) {
      score += 20;
    } else if (carbRatio >= 0.6 && carbRatio <= 1.3) {
      score += 12;
    } else {
      score += 5;
    }

    // Fat (10 points)
    final fatRatio = consumedFat / targetFat;
    if (fatRatio >= 0.7 && fatRatio <= 1.1) {
      score += 10;
    } else if (fatRatio >= 0.5 && fatRatio <= 1.3) {
      score += 6;
    } else {
      score += 2;
    }

    return score.round().clamp(0, 100);
  }
}

class MacroTargets {
  final int proteinG;
  final int carbsG;
  final int fatG;

  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  Map<String, dynamic> toMap() => {
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };

  factory MacroTargets.fromMap(Map<String, dynamic> map) => MacroTargets(
        proteinG: (map['proteinG'] as num).toInt(),
        carbsG: (map['carbsG'] as num).toInt(),
        fatG: (map['fatG'] as num).toInt(),
      );
}
