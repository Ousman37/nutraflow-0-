import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../meal/services/meal_service.dart';
import '../../../core/utils/calorie_calculator.dart';

class DayStats {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int score;
  final int mealCount;

  const DayStats({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.score,
    required this.mealCount,
  });
}

class AnalyticsController extends GetxController {
  final _mealService = MealService();
  final _authController = Get.find<AuthController>();

  final RxList<DayStats> weeklyStats = <DayStats>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWeeklyData();
  }

  Future<void> loadWeeklyData() async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;

    isLoading.value = true;
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final meals = await _mealService.getMealsForWeek(
        userId: uid,
        weekStart: start,
      );

      final stats = <DayStats>[];
      for (var i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        final dayMeals = meals.where((m) {
          final d = m.createdAt;
          return d.year == day.year &&
              d.month == day.month &&
              d.day == day.day;
        }).toList();

        final cal = dayMeals.fold<double>(0, (s, m) => s + m.nutrition.calories);
        final prot = dayMeals.fold<double>(0, (s, m) => s + m.nutrition.proteinG);
        final carb = dayMeals.fold<double>(0, (s, m) => s + m.nutrition.carbsG);
        final fat = dayMeals.fold<double>(0, (s, m) => s + m.nutrition.fatG);

        final target = _authController.userProfile.value?.dailyCalorieTarget ?? 2000;
        final protTarget = (_authController.userProfile.value?.macroTargets.proteinG ?? 150).toDouble();
        final carbTarget = (_authController.userProfile.value?.macroTargets.carbsG ?? 225).toDouble();
        final fatTarget = (_authController.userProfile.value?.macroTargets.fatG ?? 65).toDouble();

        final score = dayMeals.isEmpty
            ? 0
            : CalorieCalculator.calculateNutritionScore(
                consumedCalories: cal,
                targetCalories: target,
                consumedProtein: prot,
                targetProtein: protTarget,
                consumedCarbs: carb,
                targetCarbs: carbTarget,
                consumedFat: fat,
                targetFat: fatTarget,
              );

        stats.add(DayStats(
          date: day,
          calories: cal,
          protein: prot,
          carbs: carb,
          fat: fat,
          score: score,
          mealCount: dayMeals.length,
        ));
      }
      weeklyStats.value = stats;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  double get avgWeeklyScore {
    final active = weeklyStats.where((d) => d.mealCount > 0).toList();
    if (active.isEmpty) return 0;
    return active.fold<double>(0, (s, d) => s + d.score) / active.length;
  }

  int get currentStreak {
    int streak = 0;
    final today = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      final hasData = weeklyStats.any((d) =>
          d.date.year == day.year &&
          d.date.month == day.month &&
          d.date.day == day.day &&
          d.mealCount > 0);
      if (hasData) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  int get totalMealsThisWeek =>
      weeklyStats.fold(0, (s, d) => s + d.mealCount);
}
