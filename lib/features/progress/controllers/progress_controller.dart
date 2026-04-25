import 'package:get/get.dart';
import '../models/workout_model.dart';
import '../services/workout_service.dart';
import '../services/streak_service.dart';
import '../../meal/models/meal_model.dart';
import '../../meal/services/meal_service.dart';
import '../../auth/controllers/auth_controller.dart';

class ProgressController extends GetxController {
  final _workoutService = WorkoutService();
  final _mealService = MealService();
  final _streakService = StreakService();
  final _authController = Get.find<AuthController>();

  final RxList<WorkoutModel> weekWorkouts = <WorkoutModel>[].obs;
  final RxList<MealModel> weekMeals = <MealModel>[].obs;
  final RxInt currentStreak = 0.obs;
  final RxInt longestStreak = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final results = await Future.wait([
        _workoutService.getWorkoutsForWeek(userId: uid, weekStart: start),
        _mealService.getMealsForWeek(userId: uid, weekStart: start),
        _streakService.updateStreak(uid),
      ]);

      weekWorkouts.value = results[0] as List<WorkoutModel>;
      weekMeals.value = results[1] as List<MealModel>;
      final streakData = results[2] as StreakData;
      currentStreak.value = streakData.streakCount;
      longestStreak.value = streakData.longestStreak;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // Computed stats
  int get totalWorkoutMinutes =>
      weekWorkouts.fold(0, (sum, w) => sum + w.durationMinutes);

  double get totalCaloriesBurned =>
      weekWorkouts.fold(0.0, (sum, w) => sum + (w.caloriesBurned ?? 0));

  int get mealDaysLogged {
    final days = <String>{};
    for (final m in weekMeals) {
      final d = m.createdAt;
      days.add('${d.year}-${d.month}-${d.day}');
    }
    return days.length;
  }

  double get avgCaloriesPerDay {
    if (weekMeals.isEmpty) return 0;
    final days = <String, double>{};
    for (final m in weekMeals) {
      final d = m.createdAt;
      final key = '${d.year}-${d.month}-${d.day}';
      days[key] = (days[key] ?? 0) + m.nutrition.calories;
    }
    return days.values.fold(0.0, (a, b) => a + b) / days.length;
  }

  double get avgProteinPerDay {
    if (weekMeals.isEmpty) return 0;
    final days = <String, double>{};
    for (final m in weekMeals) {
      final d = m.createdAt;
      final key = '${d.year}-${d.month}-${d.day}';
      days[key] = (days[key] ?? 0) + m.nutrition.proteinG;
    }
    return days.values.fold(0.0, (a, b) => a + b) / days.length;
  }

  // Calories per weekday (Mon=0..Sun=6) for bar chart
  List<double> get caloriesPerWeekday {
    final result = List<double>.filled(7, 0);
    for (final m in weekMeals) {
      final wd = m.createdAt.weekday - 1; // Mon=0
      if (wd >= 0 && wd < 7) result[wd] += m.nutrition.calories;
    }
    return result;
  }

  String get aiInsight {
    if (weekMeals.isEmpty && weekWorkouts.isEmpty) {
      return 'Start logging meals and workouts to get personalized weekly insights here.';
    }
    final streak = currentStreak.value;
    final mins = totalWorkoutMinutes;
    final cals = avgCaloriesPerDay;

    final parts = <String>[];
    if (streak >= 3) {
      parts.add('You\'re on a $streak-day streak — great consistency!');
    }
    if (mins > 0) {
      parts.add(
          'You\'ve been active for $mins minutes this week${totalCaloriesBurned > 0 ? ', burning ${totalCaloriesBurned.round()} kcal' : ''}.');
    }
    if (cals > 0) {
      parts.add(
          'Averaging ${cals.round()} kcal/day on tracked days — keep aiming for your target.');
    }
    if (parts.isEmpty) return 'Keep logging to see your weekly summary here.';
    return parts.join(' ');
  }
}
