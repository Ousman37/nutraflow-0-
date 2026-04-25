import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/onboarding_data.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  final _authController = Get.find<AuthController>();

  final PageController pageController = PageController();
  final RxInt currentStep = 0.obs;
  final RxBool isLoading = false.obs;
  final int totalSteps = 4;

  // ── Step 0 — Personal Info ──────────────────────────────────────────────────
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final RxString gender = 'male'.obs;

  // ── Step 1 — Goal (NutraFlow pill-style options) ────────────────────────────
  // Visual labels shown in the pill UI → mapped to FitnessGoal for persistence
  static const Map<String, FitnessGoal> nutraGoals = {
    'Build healthy habits': FitnessGoal.improveHealth,
    'Track meals mindfully': FitnessGoal.maintain,
    'Support energy': FitnessGoal.gainMuscle,
    'Increase meal nutrition': FitnessGoal.loseWeight,
  };

  final Rx<FitnessGoal?> selectedGoal = Rx<FitnessGoal?>(null);
  final RxString selectedGoalLabel = ''.obs;

  void selectNutraGoal(String label) {
    selectedGoalLabel.value = label;
    selectedGoal.value = nutraGoals[label];
  }

  // Selects a goal and auto-advances after the selection animation plays.
  // Guards against double-advance if the user taps multiple pills quickly.
  void selectNutraGoalAndAdvance(String label) {
    selectNutraGoal(label);
    Future.delayed(const Duration(milliseconds: 340), () {
      if (selectedGoalLabel.value == label && canProceed.value) {
        nextStep();
      }
    });
  }

  // ── Step 2 — Activity ───────────────────────────────────────────────────────
  final Rx<ActivityLevel?> selectedActivity = Rx<ActivityLevel?>(null);

  // ── Step 3 — Dietary ────────────────────────────────────────────────────────
  final RxList<String> selectedDietaryPrefs = <String>[].obs;

  static const List<String> dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'None',
  ];

  // ── Reactive validation ─────────────────────────────────────────────────────
  final RxBool canProceed = false.obs;
  final RxString nameError = ''.obs;
  final RxString ageError = ''.obs;
  final RxString heightError = ''.obs;
  final RxString weightError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_validatePersonalInfo);
    ageController.addListener(_validatePersonalInfo);
    heightController.addListener(_validatePersonalInfo);
    weightController.addListener(_validatePersonalInfo);
    ever(gender, (_) => _validatePersonalInfo());
    ever(selectedGoal, (_) => _updateCanProceed());
    ever(selectedActivity, (_) => _updateCanProceed());
    ever(currentStep, (_) => _updateCanProceed());
    _updateCanProceed();
  }

  @override
  void onClose() {
    pageController.dispose();
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.onClose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  void _validatePersonalInfo() {
    final name = nameController.text.trim();
    final ageRaw = ageController.text.trim();
    final heightRaw = heightController.text.trim();
    final weightRaw = weightController.text.trim();

    nameError.value = name.isEmpty ? 'Name is required' : '';

    final age = int.tryParse(ageRaw);
    if (ageRaw.isEmpty) {
      ageError.value = '';
    } else if (age == null) {
      ageError.value = 'Enter a valid number';
    } else if (age < 10 || age > 100) {
      ageError.value = 'Must be between 10 – 100';
    } else {
      ageError.value = '';
    }

    final height = double.tryParse(heightRaw);
    if (heightRaw.isEmpty) {
      heightError.value = '';
    } else if (height == null) {
      heightError.value = 'Enter a valid number';
    } else if (height < 100 || height > 250) {
      heightError.value = 'Must be between 100 – 250 cm';
    } else {
      heightError.value = '';
    }

    final weight = double.tryParse(weightRaw);
    if (weightRaw.isEmpty) {
      weightError.value = '';
    } else if (weight == null) {
      weightError.value = 'Enter a valid number';
    } else if (weight < 30 || weight > 300) {
      weightError.value = 'Must be between 30 – 300 kg';
    } else {
      weightError.value = '';
    }

    _updateCanProceed();
  }

  bool get _step0Valid {
    final age = int.tryParse(ageController.text.trim());
    final height = double.tryParse(heightController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    return nameController.text.trim().isNotEmpty &&
        age != null &&
        age >= 10 &&
        age <= 100 &&
        height != null &&
        height >= 100 &&
        height <= 250 &&
        weight != null &&
        weight >= 30 &&
        weight <= 300;
  }

  void _updateCanProceed() {
    switch (currentStep.value) {
      case 0:
        canProceed.value = _step0Valid;
      case 1:
        canProceed.value = selectedGoal.value != null;
      case 2:
        canProceed.value = selectedActivity.value != null;
      case 3:
        canProceed.value = true;
      default:
        canProceed.value = false;
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void nextStep() {
    if (!canProceed.value) return;
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void toggleDietaryPref(String pref) {
    if (pref == 'None') {
      selectedDietaryPrefs.value = ['None'];
      return;
    }
    selectedDietaryPrefs.remove('None');
    if (selectedDietaryPrefs.contains(pref)) {
      selectedDietaryPrefs.remove(pref);
    } else {
      selectedDietaryPrefs.add(pref);
    }
  }

  Future<void> _completeOnboarding() async {
    final args = Get.arguments as Map<String, dynamic>?;
    final uid = args?['uid'] as String? ?? _authController.currentUserId;
    final email = args?['email'] as String? ??
        (_authController.firebaseUser.value?.email ?? '');

    if (uid.isEmpty) return;

    try {
      isLoading.value = true;
      await _authController.saveUserProfile(
        uid: uid,
        name: nameController.text.trim(),
        email: email,
        age: int.parse(ageController.text.trim()),
        heightCm: double.parse(heightController.text.trim()),
        weightKg: double.parse(weightController.text.trim()),
        gender: gender.value,
        goal: selectedGoal.value!,
        activityLevel: selectedActivity.value!,
        dietaryPreferences: selectedDietaryPrefs.isEmpty
            ? ['None']
            : List.from(selectedDietaryPrefs),
      );
      // Go to motivation screen before entering the app
      Get.offAllNamed(AppRoutes.motivation);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save your profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
