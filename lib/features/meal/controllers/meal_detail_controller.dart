import 'package:get/get.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../meals/controllers/meals_controller.dart';
import '../../journal/controllers/journal_controller.dart';

class MealDetailController extends GetxController {
  final _mealService = MealService();
  final _authController = Get.find<AuthController>();

  late final MealModel meal;
  final RxBool isLoggingAgain = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is MealModel) {
      meal = args;
    } else {
      Get.back();
    }
  }

  // Duplicates this meal as a new entry logged right now — skips AI
  // analysis entirely since the nutrition data is already known.
  Future<void> logAgain() async {
    isLoggingAgain.value = true;
    try {
      await _mealService.saveMeal(
        userId: _authController.currentUserId,
        name: meal.name,
        type: meal.type,
        nutrition: meal.nutrition,
        imageUrl: meal.imageUrl,
        description: meal.description,
      );
      await _refreshListeners();
      Get.back();
      Get.snackbar('Logged', '${meal.name} added to today\'s meals.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoggingAgain.value = false;
    }
  }

  Future<void> _refreshListeners() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().refresh();
    }
    if (Get.isRegistered<MealsController>()) {
      await Get.find<MealsController>().loadMeals();
    }
    if (Get.isRegistered<JournalController>()) {
      await Get.find<JournalController>().fetchMeals();
    }
  }

  Future<void> deleteMeal() async {
    try {
      await _mealService.deleteMeal(
        userId: _authController.currentUserId,
        mealId: meal.id,
      );
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refresh();
      }
      Get.back();
      Get.snackbar('Deleted', 'Meal has been removed.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
