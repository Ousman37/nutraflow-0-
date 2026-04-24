import '../../onboarding/models/onboarding_data.dart';
import '../../../core/utils/calorie_calculator.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final int age;
  final double heightCm;
  final double weightKg;
  final String gender;
  final FitnessGoal goal;
  final ActivityLevel activityLevel;
  final List<String> dietaryPreferences;
  final double dailyCalorieTarget;
  final MacroTargets macroTargets;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.dietaryPreferences,
    required this.dailyCalorieTarget,
    required this.macroTargets,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'gender': gender,
        'goal': goal.key,
        'activityLevel': activityLevel.key,
        'dietaryPreferences': dietaryPreferences,
        'dailyCalorieTarget': dailyCalorieTarget,
        'macroTargets': macroTargets.toMap(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      age: (map['age'] as num).toInt(),
      heightCm: (map['heightCm'] as num).toDouble(),
      weightKg: (map['weightKg'] as num).toDouble(),
      gender: map['gender'] as String? ?? 'male',
      goal: FitnessGoalExt.fromKey(map['goal'] as String),
      activityLevel: ActivityLevelExt.fromKey(map['activityLevel'] as String),
      dietaryPreferences: List<String>.from(map['dietaryPreferences'] ?? []),
      dailyCalorieTarget: (map['dailyCalorieTarget'] as num).toDouble(),
      macroTargets: MacroTargets.fromMap(
        Map<String, dynamic>.from(map['macroTargets']),
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  UserProfileModel copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? gender,
    FitnessGoal? goal,
    ActivityLevel? activityLevel,
    List<String>? dietaryPreferences,
    double? dailyCalorieTarget,
    MacroTargets? macroTargets,
  }) {
    return UserProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      macroTargets: macroTargets ?? this.macroTargets,
      createdAt: createdAt,
    );
  }
}
