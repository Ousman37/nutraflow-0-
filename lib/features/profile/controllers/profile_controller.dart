import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_profile_model.dart';
import '../../auth/services/firestore_service.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../../core/utils/calorie_calculator.dart';

class ProfileController extends GetxController {
  final _authController = Get.find<AuthController>();
  final _firestoreService = FirestoreService();

  final RxBool isSaving = false.obs;

  Rx<UserProfileModel?> get profileObs => _authController.userProfile;
  UserProfileModel? get profile => _authController.userProfile.value;
  String get name => _authController.currentUserName;

  Future<void> signOut() async {
    await _authController.signOut();
  }

  Future<void> updateProfile({
    required int age,
    required double weightKg,
    required double heightCm,
    required String gender,
    required FitnessGoal goal,
    required ActivityLevel activityLevel,
    required List<String> dietaryPreferences,
  }) async {
    isSaving.value = true;
    try {
      final current = _authController.userProfile.value;
      if (current == null) return;

      final bmr = CalorieCalculator.calculateBMR(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
      );
      final tdee = CalorieCalculator.calculateTDEE(
        bmr: bmr,
        activityLevel: activityLevel,
      );
      final dailyCalories = CalorieCalculator.calculateDailyCalories(
        tdee: tdee,
        goal: goal,
      );
      final macros = CalorieCalculator.calculateMacros(dailyCalories);

      final updated = current.copyWith(
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        gender: gender,
        goal: goal,
        activityLevel: activityLevel,
        dietaryPreferences:
            dietaryPreferences.isEmpty ? ['None'] : dietaryPreferences,
        dailyCalorieTarget: dailyCalories,
        macroTargets: macros,
      );

      await _firestoreService.updateUserProfile(current.id, updated.toMap());
      _authController.userProfile.value = updated;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteAccount() async {
    isSaving.value = true;
    try {
      final uid = _authController.currentUserId;
      if (uid.isNotEmpty) await _firestoreService.deleteUserData(uid);
      await _authController.deleteAccount();
      return true;
    } catch (_) {
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
