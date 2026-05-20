import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../meal/models/meal_model.dart';
import '../../meal/services/meal_service.dart';
import '../../water/services/water_service.dart';
import '../../../core/utils/calorie_calculator.dart';

class HomeController extends GetxController {
  final _mealService = MealService();
  final _waterService = WaterService();
  final _authController = Get.find<AuthController>();

  final RxList<MealModel> todaysMeals = <MealModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedTabIndex = 0.obs;
  final RxInt waterGlasses = 0.obs;

  static const int waterGoal = 8;
  static const int mlPerGlass = 250;

  // Week-day selector — 0=Mon … 6=Sun, defaults to today
  final RxInt selectedDayIndex = RxInt(DateTime.now().weekday - 1);

  @override
  void onInit() {
    super.onInit();
    _loadMealsForDate(selectedDate);
    _loadWaterForDate(selectedDate);
  }

  // ── Week helpers ────────────────────────────────────────────────────────────

  List<DateTime> get currentWeekDays {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  DateTime get selectedDate => currentWeekDays[selectedDayIndex.value];

  bool get selectedDateIsToday {
    final d = selectedDate;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void selectDay(int index) {
    if (selectedDayIndex.value == index) return;
    selectedDayIndex.value = index;
    _loadMealsForDate(selectedDate);
    _loadWaterForDate(selectedDate);
  }

  // ── Meal loading ────────────────────────────────────────────────────────────

  Future<void> _loadMealsForDate(DateTime date) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;

    isLoading.value = true;
    try {
      final meals = await _mealService.getMealsForDate(
        userId: uid,
        date: date,
      );
      todaysMeals.value = meals;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      _loadMealsForDate(selectedDate),
      _loadWaterForDate(selectedDate),
    ]);
  }

  // ── Water tracking ──────────────────────────────────────────────────────────

  Future<void> _loadWaterForDate(DateTime date) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    try {
      waterGlasses.value = await _waterService.getGlasses(uid, date);
    } catch (_) {}
  }

  Future<void> addWaterGlass() async {
    if (waterGlasses.value >= waterGoal) return;
    waterGlasses.value++;
    _saveWater();
  }

  Future<void> removeWaterGlass() async {
    if (waterGlasses.value <= 0) return;
    waterGlasses.value--;
    _saveWater();
  }

  Future<void> setWaterGlasses(int count) async {
    waterGlasses.value = count.clamp(0, waterGoal);
    _saveWater();
  }

  void _saveWater() {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    _waterService.setGlasses(uid, selectedDate, waterGlasses.value);
  }

  int get waterMl => waterGlasses.value * mlPerGlass;

  // ── Nutrition aggregates ────────────────────────────────────────────────────

  double get totalCalories =>
      todaysMeals.fold(0, (sum, m) => sum + m.nutrition.calories);

  double get totalProtein =>
      todaysMeals.fold(0, (sum, m) => sum + m.nutrition.proteinG);

  double get totalCarbs =>
      todaysMeals.fold(0, (sum, m) => sum + m.nutrition.carbsG);

  double get totalFat =>
      todaysMeals.fold(0, (sum, m) => sum + m.nutrition.fatG);

  double get calorieTarget =>
      _authController.userProfile.value?.dailyCalorieTarget ?? 2000;

  double get proteinTarget =>
      (_authController.userProfile.value?.macroTargets.proteinG ?? 150)
          .toDouble();

  double get carbsTarget =>
      (_authController.userProfile.value?.macroTargets.carbsG ?? 225)
          .toDouble();

  double get fatTarget =>
      (_authController.userProfile.value?.macroTargets.fatG ?? 65).toDouble();

  int get dailyScore {
    if (todaysMeals.isEmpty) return 0;
    return CalorieCalculator.calculateNutritionScore(
      consumedCalories: totalCalories,
      targetCalories: calorieTarget,
      consumedProtein: totalProtein,
      targetProtein: proteinTarget,
      consumedCarbs: totalCarbs,
      targetCarbs: carbsTarget,
      consumedFat: totalFat,
      targetFat: fatTarget,
    );
  }

  double get calorieProgress =>
      calorieTarget > 0 ? (totalCalories / calorieTarget).clamp(0.0, 1.0) : 0;

  // ── Score-based labels for the circular widget ──────────────────────────────

  String get scoreEncouragement {
    final s = dailyScore;
    if (s >= 80) return 'Keep Up The\nExcellent Work!';
    if (s >= 60) return 'Eat More\nNutritional Food';
    if (s >= 40) return 'Add More\nVariety Today';
    return 'Focus on\nBalanced Meals';
  }

  String get scoreLevel {
    final s = dailyScore;
    if (s >= 80) return 'Elite Level';
    if (s >= 60) return 'Wealthy Level';
    if (s >= 40) return 'Progress Level';
    return 'Starting Level';
  }

  // ── Meal access ─────────────────────────────────────────────────────────────

  MealModel? getMealByType(MealType type) {
    try {
      return todaysMeals.lastWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  int get loggedMealCount =>
      MealType.values.where((t) => t != MealType.snack).fold(
        0,
        (count, t) => count + (getMealByType(t) != null ? 1 : 0),
      );

  String get mealTimeGap {
    final logged = MealType.values
        .where((t) => t != MealType.snack)
        .map((t) => getMealByType(t))
        .whereType<MealModel>()
        .toList();
    if (logged.length < 2) return '0h 0m mins gap';
    logged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final diff = logged.last.createdAt.difference(logged.first.createdAt);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m mins gap';
  }

  String get userName => _authController.currentUserName;
}
