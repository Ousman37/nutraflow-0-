import 'package:get/get.dart';
import '../../meal/models/meal_model.dart';
import '../../meal/services/meal_service.dart';
import '../../auth/controllers/auth_controller.dart';

class MealsController extends GetxController {
  final _mealService = MealService();
  final _authController = Get.find<AuthController>();

  final RxList<MealModel> meals = <MealModel>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMeals();
  }

  Future<void> loadMeals() async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final result = await _mealService.getMealsForDate(
        userId: uid,
        date: selectedDate.value,
      );
      meals.value = result;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadMeals();
  }

  void previousDay() => selectDate(selectedDate.value.subtract(const Duration(days: 1)));
  void nextDay() => selectDate(selectedDate.value.add(const Duration(days: 1)));

  bool get isToday {
    final now = DateTime.now();
    final d = selectedDate.value;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  List<DateTime> get currentWeekDays {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<MealModel> mealsForType(MealType type) =>
      meals.where((m) => m.type == type).toList();

  double get totalCalories =>
      meals.fold(0, (sum, m) => sum + m.nutrition.calories);

  double get totalProtein =>
      meals.fold(0, (sum, m) => sum + m.nutrition.proteinG);

  double get totalCarbs =>
      meals.fold(0, (sum, m) => sum + m.nutrition.carbsG);

  double get totalFat =>
      meals.fold(0, (sum, m) => sum + m.nutrition.fatG);

  Future<void> deleteMeal(String mealId) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    await _mealService.deleteMeal(userId: uid, mealId: mealId);
    await loadMeals();
  }
}
