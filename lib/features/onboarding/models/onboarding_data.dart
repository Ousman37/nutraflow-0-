import 'package:phosphor_flutter/phosphor_flutter.dart';

enum FitnessGoal {
  loseWeight,
  maintain,
  gainMuscle,
  improveHealth,
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

extension FitnessGoalExt on FitnessGoal {
  String get label {
    switch (this) {
      case FitnessGoal.loseWeight:
        return 'Lose Weight';
      case FitnessGoal.maintain:
        return 'Maintain Weight';
      case FitnessGoal.gainMuscle:
        return 'Gain Muscle';
      case FitnessGoal.improveHealth:
        return 'Improve Health';
    }
  }

  String get emoji {
    switch (this) {
      case FitnessGoal.loseWeight:
        return '🔥';
      case FitnessGoal.maintain:
        return '⚖️';
      case FitnessGoal.gainMuscle:
        return '💪';
      case FitnessGoal.improveHealth:
        return '❤️';
    }
  }

  PhosphorIconData get icon {
    switch (this) {
      case FitnessGoal.loseWeight:
        return PhosphorIcons.fire();
      case FitnessGoal.maintain:
        return PhosphorIcons.scales();
      case FitnessGoal.gainMuscle:
        return PhosphorIcons.barbell();
      case FitnessGoal.improveHealth:
        return PhosphorIcons.heart();
    }
  }

  String get description {
    switch (this) {
      case FitnessGoal.loseWeight:
        return 'Reduce body fat and reach your ideal weight';
      case FitnessGoal.maintain:
        return 'Keep your current weight and stay balanced';
      case FitnessGoal.gainMuscle:
        return 'Build lean muscle and increase strength';
      case FitnessGoal.improveHealth:
        return 'Eat better and feel your best every day';
    }
  }

  String get key {
    return name;
  }

  static FitnessGoal fromKey(String key) {
    return FitnessGoal.values.firstWhere((e) => e.name == key);
  }
}

extension ActivityLevelExt on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityLevel.sedentary:
        return '🛋️';
      case ActivityLevel.lightlyActive:
        return '🚶';
      case ActivityLevel.moderatelyActive:
        return '🏃';
      case ActivityLevel.veryActive:
        return '🏋️';
      case ActivityLevel.extremelyActive:
        return '⚡';
    }
  }

  PhosphorIconData get icon {
    switch (this) {
      case ActivityLevel.sedentary:
        return PhosphorIcons.couch();
      case ActivityLevel.lightlyActive:
        return PhosphorIcons.personSimpleWalk();
      case ActivityLevel.moderatelyActive:
        return PhosphorIcons.personSimpleRun();
      case ActivityLevel.veryActive:
        return PhosphorIcons.barbell();
      case ActivityLevel.extremelyActive:
        return PhosphorIcons.lightning();
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise, desk job';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1–3 days per week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3–5 days per week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6–7 days per week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
    }
  }

  String get key => name;

  static ActivityLevel fromKey(String key) {
    return ActivityLevel.values.firstWhere((e) => e.name == key);
  }
}
