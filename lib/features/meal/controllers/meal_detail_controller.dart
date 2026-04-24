import 'package:get/get.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';

class MealDetailController extends GetxController {
  final _mealService = MealService();
  final _authController = Get.find<AuthController>();

  late final MealModel meal;

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
