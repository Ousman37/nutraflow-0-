import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/add_meal_controller.dart';
import '../models/meal_model.dart';
import '../widgets/macro_breakdown_card.dart';
import '../widgets/rainbow_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_overlay.dart';

class AddMealView extends StatefulWidget {
  const AddMealView({super.key});

  @override
  State<AddMealView> createState() => _AddMealViewState();
}

class _AddMealViewState extends State<AddMealView> {
  late final AddMealController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(AddMealController());
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['preselectedType'] != null) {
      _ctrl.selectedMealType.value = args!['preselectedType'] as MealType;
    }
    final method = args?['method'] as String?;
    if (method != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (method == 'camera') _ctrl.pickImageFromCamera();
        if (method == 'gallery') _ctrl.pickImageFromGallery();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        return Stack(
          children: [
            _ctrl.currentStep.value == 0
                ? _InputStep(ctrl: _ctrl)
                : _AnalysisStep(ctrl: _ctrl),
            if (_ctrl.isAnalyzing.value)
              const LoadingOverlay(message: 'Analyzing your meal with AI...'),
            if (_ctrl.isSaving.value)
              const LoadingOverlay(message: 'Saving meal...'),
          ],
        );
      }),
    );
  }
}

class _InputStep extends StatelessWidget {
  final AddMealController ctrl;
  const _InputStep({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _AppBar(title: 'Add Meal', onBack: Get.back),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal Type', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  _MealTypeSelector(ctrl: ctrl),
                  const SizedBox(height: 28),
                  Text(
                    'How would you like to add\nyour meal?',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  _InputOptionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take a Photo',
                    subtitle: 'Snap your meal for instant AI analysis',
                    gradient: AppColors.primaryGradient,
                    onTap: ctrl.pickImageFromCamera,
                  ),
                  const SizedBox(height: 12),
                  _InputOptionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Import from Gallery',
                    subtitle: 'Choose an existing photo',
                    gradient: [AppColors.secondary, const Color(0xFFB06CF8)],
                    onTap: ctrl.pickImageFromGallery,
                  ),
                  const SizedBox(height: 24),
                  _TextInputSection(ctrl: ctrl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal type chips
// ─────────────────────────────────────────────────────────────────────────────

class _MealTypeSelector extends StatelessWidget {
  final AddMealController ctrl;
  const _MealTypeSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: MealType.values.map((type) {
            final isSelected = ctrl.selectedMealType.value == type;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ctrl.selectedMealType.value = type;
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  // Min 44px tall so the chip is always easy to tap
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type.icon,
                        size: 20,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.label,
                        style: AppTextStyles.captionText.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input option card — Material + InkWell for instant ripple feedback
// ─────────────────────────────────────────────────────────────────────────────

class _InputOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _InputOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          splashColor: gradient.first.withValues(alpha: 0.08),
          highlightColor: gradient.first.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 3),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text input section
// ─────────────────────────────────────────────────────────────────────────────

class _TextInputSection extends StatelessWidget {
  final AddMealController ctrl;
  const _TextInputSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or describe it', style: AppTextStyles.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        Text('Describe your meal', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl.descriptionController,
          maxLines: 4,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText:
                'e.g. Grilled chicken breast with brown rice and steamed broccoli',
            hintStyle: AppTextStyles.bodyMedium,
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          text: 'Analyze with AI ✨',
          onPressed: ctrl.analyzeFromDescription,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analysis step
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisStep extends StatelessWidget {
  final AddMealController ctrl;
  const _AnalysisStep({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _AppBar(
            title: 'AI Analysis',
            onBack: ctrl.resetAnalysis,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Obx(() {
                final analysis = ctrl.analysisResult.value;
                if (analysis == null) return const SizedBox.shrink();

                return Column(
                  children: [
                    if (ctrl.selectedImage.value != null)
                      _MealImagePreview(file: ctrl.selectedImage.value!),
                    const SizedBox(height: 16),
                    _MealNameField(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _ScoreCard(score: analysis.score),
                    const SizedBox(height: 16),
                    MacroBreakdownCard(nutrition: analysis),
                    const SizedBox(height: 16),
                    _FeedbackCard(
                      feedback: analysis.feedback,
                      suggestions: analysis.suggestions,
                    ),
                    const SizedBox(height: 16),
                    RainbowIndicator(colorGroups: analysis.colorGroups),
                    const SizedBox(height: 24),
                    Obx(() => GradientButton(
                          text: 'Save Meal',
                          isLoading: ctrl.isSaving.value,
                          onPressed: ctrl.saveMeal,
                        )),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: ctrl.resetAnalysis,
                      child: Text(
                        'Re-analyze',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealImagePreview extends StatelessWidget {
  final File file;
  const _MealImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        file,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MealNameField extends StatefulWidget {
  final AddMealController ctrl;
  const _MealNameField({required this.ctrl});

  @override
  State<_MealNameField> createState() => _MealNameFieldState();
}

class _MealNameFieldState extends State<_MealNameField> {
  late final TextEditingController _textCtrl;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    final initial = widget.ctrl.mealName.value;
    _textCtrl = TextEditingController(text: initial)
      ..selection = TextSelection.collapsed(offset: initial.length);
    // Sync text if the RxString is updated externally (e.g. resetAnalysis)
    _worker = ever(widget.ctrl.mealName, (String val) {
      if (_textCtrl.text != val) {
        _textCtrl.value = TextEditingValue(
          text: val,
          selection: TextSelection.collapsed(offset: val.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textCtrl,
      onChanged: (v) => widget.ctrl.mealName.value = v,
      style: AppTextStyles.headlineSmall,
      decoration: InputDecoration(
        hintText: 'Meal name',
        hintStyle:
            AppTextStyles.headlineSmall.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  const _ScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition Score', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? 'Excellent nutritional balance!'
                      : score >= 60
                          ? 'Good choice overall.'
                          : 'Could be more balanced.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String feedback;
  final List<String> suggestions;

  const _FeedbackCard({
    required this.feedback,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('AI Feedback', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(feedback, style: AppTextStyles.bodyLarge),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(s, style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar — 44×44 back button with haptic feedback
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _AppBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Text(title, style: AppTextStyles.headlineMedium),
        ],
      ),
    );
  }
}
