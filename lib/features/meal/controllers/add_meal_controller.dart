import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal_model.dart';
import '../models/nutrition_analysis.dart';
import '../services/ai_nutrition_service.dart';
import '../services/meal_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../rewards/controllers/reward_controller.dart';
import '../../progress/services/streak_service.dart';
import '../../../routes/app_routes.dart';

class AddMealController extends GetxController {
  final _aiService = AINutritionService();
  final _mealService = MealService();
  final _authController = Get.find<AuthController>();
  final _imagePicker = ImagePicker();

  final TextEditingController descriptionController = TextEditingController();
  final RxString mealName = ''.obs;
  final Rx<MealType> selectedMealType = MealType.breakfast.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<NutritionAnalysis?> analysisResult = Rx<NutritionAnalysis?>(null);
  final RxBool isAnalyzing = false.obs;
  final RxBool isSaving = false.obs;
  final RxInt currentStep = 0.obs; // 0 = input, 1 = analysis result

  @override
  void onInit() {
    super.onInit();
    _suggestMealType();
    // Pre-load an image passed from the scanner screen.
    final args = Get.arguments;
    if (args is Map && args['image'] is File) {
      selectedImage.value = args['image'] as File;
      WidgetsBinding.instance.addPostFrameCallback((_) => analyzeWithImage());
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }

  // ── Meal-type suggestion ────────────────────────────────────────────────────

  void _suggestMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) {
      selectedMealType.value = MealType.breakfast;
    } else if (hour < 14) {
      selectedMealType.value = MealType.lunch;
    } else if (hour < 19) {
      selectedMealType.value = MealType.dinner;
    } else {
      selectedMealType.value = MealType.snack;
    }
  }

  // ── Image picking ───────────────────────────────────────────────────────────

  Future<void> pickImageFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      selectedImage.value = File(picked.path);
      await analyzeWithImage();
    }
  }

  Future<void> pickImageFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      selectedImage.value = File(picked.path);
      await analyzeWithImage();
    }
  }

  // ── AI analysis ─────────────────────────────────────────────────────────────

  Future<void> analyzeWithImage() async {
    if (selectedImage.value == null) return;
    if (Get.isRegistered<SubscriptionController>() &&
        !Get.find<SubscriptionController>().requireMealAccess()) {
      return;
    }
    try {
      isAnalyzing.value = true;
      currentStep.value = 1;
      final result = await _aiService.analyzeMeal(
        imagePath: selectedImage.value!.path,
        description: descriptionController.text,
      );
      analysisResult.value = result;
      if (mealName.value.isEmpty) {
        mealName.value = 'Meal — ${selectedMealType.value.label}';
      }
      if (Get.isRegistered<SubscriptionController>()) {
        Get.find<SubscriptionController>().recordAnalysis();
      }
    } catch (e) {
      Get.snackbar('Analysis Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      currentStep.value = 0;
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<void> analyzeFromDescription() async {
    final desc = descriptionController.text.trim();
    if (desc.isEmpty) {
      Get.snackbar('Empty Description', 'Please describe your meal first.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (Get.isRegistered<SubscriptionController>() &&
        !Get.find<SubscriptionController>().requireMealAccess()) {
      return;
    }
    try {
      isAnalyzing.value = true;
      currentStep.value = 1;
      final result = await _aiService.analyzeMeal(description: desc);
      analysisResult.value = result;
      if (mealName.value.isEmpty) {
        mealName.value = desc.length > 30 ? '${desc.substring(0, 30)}…' : desc;
      }
      if (Get.isRegistered<SubscriptionController>()) {
        Get.find<SubscriptionController>().recordAnalysis();
      }
    } catch (e) {
      Get.snackbar('Analysis Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      currentStep.value = 0;
    } finally {
      isAnalyzing.value = false;
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> saveMeal() async {
    if (analysisResult.value == null) return;

    final uid = _authController.currentUserId;
    if (uid.isEmpty) {
      Get.snackbar(
        'Not Signed In',
        'Please sign in before saving a meal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Button shows spinner immediately — no UI freeze.
    isSaving.value = true;

    try {
      // Image upload is best-effort: a Storage failure does not block the save.
      String? imageUrl;
      if (selectedImage.value != null) {
        try {
          imageUrl =
              await _mealService.uploadMealImage(uid, selectedImage.value!);
        } catch (e) {
          debugPrint('MealService: image upload skipped — $e');
        }
      }

      await _mealService.saveMeal(
        userId: uid,
        name: mealName.value.isNotEmpty
            ? mealName.value
            : selectedMealType.value.label,
        type: selectedMealType.value,
        nutrition: analysisResult.value!,
        imageUrl: imageUrl,
        description: descriptionController.text.trim(),
      );

      // ── Navigate back to dashboard ──────────────────────────────────────
      // Get.until pops the navigator stack until the home route is on top.
      // This removes both AddMealView and SelectMethodView in one call,
      // without recreating HomeView or losing its controller state.
      Get.until((route) => route.settings.name == AppRoutes.home);

      // Refresh the dashboard in the background — no await so it never
      // blocks the navigation or delays the success message.
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refresh();
      }

      // Update streak and check for newly unlocked rewards (fire-and-forget).
      StreakService().updateStreak(uid).then((data) {
        if (Get.isRegistered<RewardController>()) {
          Get.find<RewardController>().checkForNewRewards(data.streakCount);
        }
      });

      Get.snackbar(
        'Meal Saved',
        '${selectedMealType.value.label} logged successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      // Show the real error so you can diagnose what Firestore is rejecting.
      Get.snackbar(
        'Save Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      // Always reset loading state, even if navigation already happened.
      isSaving.value = false;
    }
  }

  // ── Reset ───────────────────────────────────────────────────────────────────

  void resetAnalysis() {
    analysisResult.value = null;
    currentStep.value = 0;
    selectedImage.value = null;
    descriptionController.clear();
    mealName.value = '';
  }
}
