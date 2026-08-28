import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_profile_model.dart';
import '../../auth/services/firestore_service.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../../core/utils/calorie_calculator.dart';

class ProfileController extends GetxController {
  final _authController = Get.find<AuthController>();
  final _firestoreService = FirestoreService();
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  final RxBool isSaving = false.obs;
  final RxBool isUploadingPhoto = false.obs;

  Rx<UserProfileModel?> get profileObs => _authController.userProfile;
  UserProfileModel? get profile => _authController.userProfile.value;
  String get name => _authController.currentUserName;
  String get email =>
      _authController.firebaseUser.value?.email ?? profile?.email ?? '';

  Future<void> pickAndUploadProfilePhoto({required ImageSource source}) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;

    isUploadingPhoto.value = true;
    try {
      final ref = _storage.ref('profile_photos/$uid/${_uuid.v4()}.jpg');
      final task = await ref.putFile(File(picked.path));
      final url = await task.ref.getDownloadURL();

      await _firestoreService.updateUserProfile(uid, {'photoUrl': url});

      final current = _authController.userProfile.value;
      if (current != null) {
        _authController.userProfile.value = current.copyWith(photoUrl: url);
      }
    } catch (_) {
      Get.snackbar(
        'Upload Failed',
        'Could not update your profile photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

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

  // Directly overrides the calculated targets — used when the user wants
  // to set their own numbers instead of the BMR/TDEE-derived defaults.
  Future<void> updateTargetsManually({
    required double dailyCalorieTarget,
    required int proteinG,
    required int carbsG,
    required int fatG,
  }) async {
    isSaving.value = true;
    try {
      final current = _authController.userProfile.value;
      if (current == null) return;

      final updated = current.copyWith(
        dailyCalorieTarget: dailyCalorieTarget,
        macroTargets: MacroTargets(
          proteinG: proteinG,
          carbsG: carbsG,
          fatG: fatG,
        ),
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
