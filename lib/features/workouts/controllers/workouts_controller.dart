import 'package:get/get.dart';
import '../../progress/models/workout_model.dart';
import '../../progress/services/workout_service.dart';
import '../../auth/controllers/auth_controller.dart';

class WorkoutsController extends GetxController {
  final _workoutService = WorkoutService();
  final _authController = Get.find<AuthController>();

  final RxList<WorkoutModel> workouts = <WorkoutModel>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWorkouts();
  }

  Future<void> loadWorkouts() async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final result = await _workoutService.getWorkoutsForDate(
        userId: uid,
        date: selectedDate.value,
      );
      workouts.value = result;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logWorkout({
    required WorkoutType type,
    required int durationMinutes,
    double? caloriesBurned,
    String? notes,
  }) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    isSaving.value = true;
    try {
      await _workoutService.saveWorkout(
        userId: uid,
        type: type,
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        notes: notes,
      );
      await loadWorkouts();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    await _workoutService.deleteWorkout(userId: uid, workoutId: workoutId);
    await loadWorkouts();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadWorkouts();
  }

  void previousDay() =>
      selectDate(selectedDate.value.subtract(const Duration(days: 1)));

  void nextDay() =>
      selectDate(selectedDate.value.add(const Duration(days: 1)));

  bool get isToday {
    final now = DateTime.now();
    final d = selectedDate.value;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  int get totalMinutes =>
      workouts.fold(0, (sum, w) => sum + w.durationMinutes);

  double get totalCaloriesBurned =>
      workouts.fold(0.0, (sum, w) => sum + (w.caloriesBurned ?? 0));
}
