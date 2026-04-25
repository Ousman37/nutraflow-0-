import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../meal/controllers/meal_detail_controller.dart';
import '../../meal/models/meal_model.dart';
import '../../meal/services/meal_service.dart';
import '../../../routes/app_routes.dart';

// One rendered section: a label and its meals.
typedef JournalSection = ({String label, List<MealModel> meals});

class JournalController extends GetxController {
  final _mealService = MealService();
  final _authController = Get.find<AuthController>();

  final RxList<MealModel> meals = <MealModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Canonical section order.
  static const _order = ['Today', 'Yesterday', 'This Week', 'Older'];

  @override
  void onInit() {
    super.onInit();
    fetchMeals();
  }

  // ── Data fetching ───────────────────────────────────────────────────────────

  Future<void> fetchMeals() async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      meals.value = await _mealService.getRecentMeals(userId: uid);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Grouping ────────────────────────────────────────────────────────────────

  /// Meals grouped into Today / Yesterday / This Week / Older, in that order.
  List<JournalSection> get sections {
    if (meals.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    // Monday of the current week.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final buckets = <String, List<MealModel>>{};

    for (final meal in meals) {
      final d = meal.createdAt;
      final mealDay = DateTime(d.year, d.month, d.day);

      final String key;
      if (mealDay == today) {
        key = 'Today';
      } else if (mealDay == yesterday) {
        key = 'Yesterday';
      } else if (!mealDay.isBefore(weekStart)) {
        key = 'This Week';
      } else {
        key = 'Older';
      }

      (buckets[key] ??= []).add(meal);
    }

    return _order
        .where(buckets.containsKey)
        .map<JournalSection>(
          (label) => (label: label, meals: buckets[label]!),
        )
        .toList();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void openDetail(MealModel meal) {
    // Always delete stale controller so onInit reads the new arguments.
    if (Get.isRegistered<MealDetailController>()) {
      Get.delete<MealDetailController>();
    }
    Get.toNamed(AppRoutes.mealDetail, arguments: meal);
  }
}
