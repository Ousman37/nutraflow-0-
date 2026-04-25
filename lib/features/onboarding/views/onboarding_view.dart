import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_data.dart';
import '../widgets/step_indicator.dart';
import '../widgets/activity_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final isBlue = ctrl.currentStep.value == 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isBlue
                ? const LinearGradient(
                    colors: AppColors.onboardingBlueGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isBlue ? null : AppColors.background,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(ctrl),
                Expanded(
                  child: PageView(
                    controller: ctrl.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _PersonalInfoStep(ctrl: ctrl),
                      _GoalStep(ctrl: ctrl),
                      _ActivityStep(ctrl: ctrl),
                      _DietaryStep(ctrl: ctrl),
                    ],
                  ),
                ),
                Obx(() => _buildBottomBar(
                      ctrl,
                      isBlue: ctrl.currentStep.value == 1,
                    )),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopBar(OnboardingController ctrl) {
    return Obx(() {
      final isBlue = ctrl.currentStep.value == 1;

      // Blue (goal) step: full-width segmented progress bar, no back arrow.
      // Cancel is handled by the bottom button on this step.
      if (isBlue) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: StepIndicator(
            currentStep: ctrl.currentStep.value,
            totalSteps: ctrl.totalSteps,
            onDarkBackground: true,
          ),
        );
      }

      // Light steps: compact indicator centered, back arrow on left.
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          children: [
            ctrl.currentStep.value > 0
                ? GestureDetector(
                    onTap: ctrl.previousStep,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : const SizedBox(width: 40),
            const Spacer(),
            StepIndicator(
              currentStep: ctrl.currentStep.value,
              totalSteps: ctrl.totalSteps,
              onDarkBackground: false,
            ),
            const Spacer(),
            const SizedBox(width: 40),
          ],
        ),
      );
    });
  }

  Widget _buildBottomBar(OnboardingController ctrl, {required bool isBlue}) {
    final enabled = ctrl.canProceed.value;
    final loading = ctrl.isLoading.value;
    final isLastStep = ctrl.currentStep.value == ctrl.totalSteps - 1;

    if (isBlue) {
      // Circular white Cancel button — goes back to the previous step.
      return Padding(
        padding: const EdgeInsets.only(bottom: 36, top: 12),
        child: GestureDetector(
          onTap: ctrl.previousStep,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Color(0xFF3D60D8),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cancel',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', 
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D60D8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Light steps — gradient button (or white outlined on last step if needed).
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1.0 : 0.45,
        child: GradientButton(
          text: isLastStep ? "Let's go! 🚀" : 'Continue',
          isLoading: loading,
          onPressed: enabled ? ctrl.nextStep : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Personal Info
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalInfoStep extends StatelessWidget {
  final OnboardingController ctrl;
  const _PersonalInfoStep({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about\nyourself', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text(
            "We'll calculate your ideal nutrition targets",
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),
          Obx(() => _ValidatedField(
                errorText: ctrl.nameError.value,
                child: CustomTextField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: ctrl.nameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              )),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Obx(() => _ValidatedField(
                      errorText: ctrl.ageError.value,
                      child: CustomTextField(
                        label: 'Age',
                        hint: '25',
                        controller: ctrl.ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                      ),
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(child: _GenderSelector(ctrl: ctrl)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Obx(() => _ValidatedField(
                      errorText: ctrl.heightError.value,
                      child: CustomTextField(
                        label: 'Height (cm)',
                        hint: '170',
                        controller: ctrl.heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => _ValidatedField(
                      errorText: ctrl.weightError.value,
                      child: CustomTextField(
                        label: 'Weight (kg)',
                        hint: '70',
                        controller: ctrl.weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidatedField extends StatelessWidget {
  final Widget child;
  final String errorText;
  const _ValidatedField({required this.child, required this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: errorText.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    errorText,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final OnboardingController ctrl;
  const _GenderSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Obx(() => Row(
              children: [
                _GenderChip(
                  label: 'Male',
                  isSelected: ctrl.gender.value == 'male',
                  onTap: () => ctrl.gender.value = 'male',
                ),
                const SizedBox(width: 8),
                _GenderChip(
                  label: 'Female',
                  isSelected: ctrl.gender.value == 'female',
                  onTap: () => ctrl.gender.value = 'female',
                ),
              ],
            )),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Goal (blue gradient, pill options, auto-advance on tap)
// ─────────────────────────────────────────────────────────────────────────────

class _GoalStep extends StatelessWidget {
  final OnboardingController ctrl;
  const _GoalStep({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                'What is your\nmain goal?',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select the option that fits your situation',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: OnboardingController.nutraGoals.keys
                .map((label) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Obx(() => _GoalPill(
                            label: label,
                            isSelected:
                                ctrl.selectedGoalLabel.value == label,
                            onTap: () =>
                                ctrl.selectNutraGoalAndAdvance(label),
                          )),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// Pill with dashed border when unselected, solid border when selected.
class _GoalPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: CustomPaint(
          painter: _DashedRoundedBorderPainter(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.50),
            isDashed: !isSelected,
            strokeWidth: isSelected ? 2.0 : 1.5,
            radius: 30,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Draws a dashed (or solid) rounded-rectangle border via CustomPainter.
// Flutter has no native dashed border support, so this is necessary.
class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  final double strokeWidth;
  final double radius;

  const _DashedRoundedBorderPainter({
    required this.color,
    required this.isDashed,
    this.strokeWidth = 1.5,
    this.radius = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    if (!isDashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }

    const dashLength = 5.0;
    const gapLength = 4.5;
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;

    double distance = 0;
    while (distance < metrics.length) {
      final end = (distance + dashLength).clamp(0.0, metrics.length);
      canvas.drawPath(metrics.extractPath(distance, end), paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) =>
      old.color != color ||
      old.isDashed != isDashed ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Activity
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityStep extends StatelessWidget {
  final OnboardingController ctrl;
  const _ActivityStep({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How active\nare you?', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text(
            'This helps us fine-tune your calorie needs',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),
          ...ActivityLevel.values.map(
            (level) => Obx(() => ActivityCard(
                  icon: level.icon,
                  title: level.label,
                  description: level.description,
                  isSelected: ctrl.selectedActivity.value == level,
                  onTap: () => ctrl.selectedActivity.value = level,
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Dietary
// ─────────────────────────────────────────────────────────────────────────────

class _DietaryStep extends StatelessWidget {
  final OnboardingController ctrl;
  const _DietaryStep({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any dietary\npreferences?',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 8),
          Text('Select all that apply', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 32),
          Obx(() => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: OnboardingController.dietaryOptions.map((pref) {
                  final selected =
                      ctrl.selectedDietaryPrefs.contains(pref);
                  return GestureDetector(
                    onTap: () => ctrl.toggleDietaryPref(pref),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        pref,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 32),
          _TargetPreview(ctrl: ctrl),
        ],
      ),
    );
  }
}

class _TargetPreview extends StatelessWidget {
  final OnboardingController ctrl;
  const _TargetPreview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your estimated targets',
            style:
                AppTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TargetItem(
                label: 'Calories',
                value: _estimateCalories(ctrl),
                unit: 'kcal',
              ),
              _TargetItem(
                label: 'Protein',
                value: _estimateProtein(ctrl),
                unit: 'g',
              ),
              _TargetItem(
                label: 'Carbs',
                value: _estimateCarbs(ctrl),
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _estimateCalories(OnboardingController ctrl) {
    try {
      final w = double.tryParse(ctrl.weightController.text) ?? 70;
      final h = double.tryParse(ctrl.heightController.text) ?? 170;
      final a = int.tryParse(ctrl.ageController.text) ?? 25;
      final bmr = 10 * w + 6.25 * h - 5 * a + 5;
      return (bmr * 1.55).round().toString();
    } catch (_) {
      return '—';
    }
  }

  String _estimateProtein(OnboardingController ctrl) {
    try {
      final w = double.tryParse(ctrl.weightController.text) ?? 70;
      return (w * 1.8).round().toString();
    } catch (_) {
      return '—';
    }
  }

  String _estimateCarbs(OnboardingController ctrl) {
    try {
      final cal = double.tryParse(_estimateCalories(ctrl)) ?? 2000;
      return ((cal * 0.45) / 4).round().toString();
    } catch (_) {
      return '—';
    }
  }
}

class _TargetItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _TargetItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style:
                AppTextStyles.headlineLarge.copyWith(color: Colors.white),
          ),
          Text(
            unit,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.captionText.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
