import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/profile_controller.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gradient_button.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: Obx(() {
            // Obx here so cards rebuild after updateProfile() updates userProfile
            ctrl.profileObs.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(ctrl: ctrl),
                const SizedBox(height: 20),
                _ProfileHeader(ctrl: ctrl),
                const SizedBox(height: 20),
                _TargetsCard(ctrl: ctrl),
                const SizedBox(height: 16),
                _InfoCard(ctrl: ctrl),
                const SizedBox(height: 16),
                _GoalActivityCard(ctrl: ctrl),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Sign Out',
                  gradient: [AppColors.error, const Color(0xFFFF9F43)],
                  onPressed: ctrl.signOut,
                  icon: PhosphorIcon(
                    PhosphorIcons.signOut(),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 12),
                _DeleteAccountButton(ctrl: ctrl),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 24),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ProfileController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowLeft(),
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text('Profile', style: AppTextStyles.displayMedium)),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Get.bottomSheet(
                _EditProfileSheet(ctrl: ctrl),
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                backgroundColor: Colors.white,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.pencilSimple(),
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header card ───────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileController ctrl;
  const _ProfileHeader({required this.ctrl});

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                ctrl.name.isNotEmpty ? ctrl.name[0].toUpperCase() : '?',
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              ctrl.name,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _TargetsCard extends StatelessWidget {
  final ProfileController ctrl;
  const _TargetsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final profile = ctrl.profile;
    if (profile == null) return const SizedBox.shrink();

    return _Card(
      title: 'Daily Targets',
      children: [
        _TargetRow(
          label: 'Calories',
          value: '${profile.dailyCalorieTarget.round()} kcal',
          color: AppColors.primary,
        ),
        _TargetRow(
          label: 'Protein',
          value: '${profile.macroTargets.proteinG}g',
          color: AppColors.proteinColor,
        ),
        _TargetRow(
          label: 'Carbs',
          value: '${profile.macroTargets.carbsG}g',
          color: AppColors.carbsColor,
        ),
        _TargetRow(
          label: 'Fat',
          value: '${profile.macroTargets.fatG}g',
          color: AppColors.fatColor,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ProfileController ctrl;
  const _InfoCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final profile = ctrl.profile;
    if (profile == null) return const SizedBox.shrink();

    return _Card(
      title: 'Body Stats',
      children: [
        _InfoRow(label: 'Age', value: '${profile.age} years'),
        _InfoRow(label: 'Height', value: '${profile.heightCm.round()} cm'),
        _InfoRow(label: 'Weight', value: '${profile.weightKg.round()} kg'),
        _InfoRow(
          label: 'BMI',
          value: _bmi(profile.weightKg, profile.heightCm),
        ),
      ],
    );
  }

  String _bmi(double weight, double height) {
    final bmi = weight / ((height / 100) * (height / 100));
    return bmi.toStringAsFixed(1);
  }
}

class _GoalActivityCard extends StatelessWidget {
  final ProfileController ctrl;
  const _GoalActivityCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final profile = ctrl.profile;
    if (profile == null) return const SizedBox.shrink();

    return _Card(
      title: 'Goal & Activity',
      children: [
        _InfoRow(
          label: 'Goal',
          value: profile.goal.label,
          icon: profile.goal.icon,
        ),
        _InfoRow(
          label: 'Activity',
          value: profile.activityLevel.label,
          icon: profile.activityLevel.icon,
        ),
        if (profile.dietaryPreferences.isNotEmpty &&
            profile.dietaryPreferences.first != 'None')
          _InfoRow(
            label: 'Diet',
            value: profile.dietaryPreferences.join(', '),
          ),
      ],
    );
  }
}

// ── Delete account button ─────────────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  final ProfileController ctrl;
  const _DeleteAccountButton({required this.ctrl});

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Delete Account?',
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'This permanently deletes your account and all data. '
              'This cannot be undone.',
              style: TextStyle(fontFamily: 'PlusJakartaSans'),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await ctrl.deleteAccount();
    if (!success) {
      Get.snackbar(
        'Error',
        'Could not delete account. If this keeps happening, sign out and sign back in first.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: ctrl.isSaving.value ? null : () => _confirm(context),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: ctrl.isSaving.value
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(PhosphorIcons.trash(),
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TargetRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
          Text(value,
              style: AppTextStyles.labelLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData? icon;
  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null) ...[
                  PhosphorIcon(icon!, size: 14, color: AppColors.textPrimary),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: AppTextStyles.labelLarge,
                    textAlign: TextAlign.right,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final ProfileController ctrl;
  const _EditProfileSheet({required this.ctrl});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late int _age;
  late double _weightKg;
  late double _heightCm;
  late String _gender;
  late FitnessGoal _goal;
  late ActivityLevel _activity;
  late List<String> _dietPrefs;

  static const _dietOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.ctrl.profile;
    _age = p?.age ?? 25;
    _weightKg = p?.weightKg ?? 70;
    _heightCm = p?.heightCm ?? 170;
    _gender = p?.gender ?? 'male';
    _goal = p?.goal ?? FitnessGoal.maintain;
    _activity = p?.activityLevel ?? ActivityLevel.moderatelyActive;
    _dietPrefs = List.from(p?.dietaryPreferences ?? ['None']);
  }

  void _toggleDiet(String option) {
    setState(() {
      if (option == 'None') {
        _dietPrefs = ['None'];
      } else {
        _dietPrefs.remove('None');
        if (_dietPrefs.contains(option)) {
          _dietPrefs.remove(option);
          if (_dietPrefs.isEmpty) _dietPrefs = ['None'];
        } else {
          _dietPrefs.add(option);
        }
      }
    });
  }

  Future<void> _save() async {
    await widget.ctrl.updateProfile(
      age: _age,
      weightKg: _weightKg,
      heightCm: _heightCm,
      gender: _gender,
      goal: _goal,
      activityLevel: _activity,
      dietaryPreferences:
          _dietPrefs.where((d) => d != 'None').toList(),
    );
    if (mounted) Get.back();
    Get.snackbar(
      'Profile Updated',
      'Your daily targets have been recalculated.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Body Stats ──
            _SheetSection(title: 'BODY STATS'),
            const SizedBox(height: 12),
            _FieldRow(
              label: 'Age',
              child: _Stepper(
                value: _age,
                min: 13,
                max: 100,
                onDecrement: () =>
                    setState(() => _age = (_age - 1).clamp(13, 100)),
                onIncrement: () =>
                    setState(() => _age = (_age + 1).clamp(13, 100)),
              ),
            ),
            const SizedBox(height: 20),
            _SliderField(
              label: 'Weight',
              value: _weightKg,
              min: 30,
              max: 200,
              unit: 'kg',
              displayValue: _weightKg.toStringAsFixed(1),
              onChanged: (v) => setState(() => _weightKg = v),
            ),
            const SizedBox(height: 16),
            _SliderField(
              label: 'Height',
              value: _heightCm,
              min: 100,
              max: 230,
              unit: 'cm',
              displayValue: '${_heightCm.round()}',
              onChanged: (v) => setState(() => _heightCm = v),
            ),
            const SizedBox(height: 20),
            _FieldRow(
              label: 'Gender',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['male', 'female'].map((g) {
                  final sel = _gender == g;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          g[0].toUpperCase() + g.substring(1),
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // ── Fitness Goal ──
            _SheetSection(title: 'FITNESS GOAL'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: FitnessGoal.values.map((g) {
                final sel = _goal == g;
                return GestureDetector(
                  onTap: () => setState(() => _goal = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.divider,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(g.icon,
                            size: 16,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            g.label,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Activity Level ──
            _SheetSection(title: 'ACTIVITY LEVEL'),
            const SizedBox(height: 12),
            ...ActivityLevel.values.map((a) {
              final sel = _activity == a;
              return GestureDetector(
                onTap: () => setState(() => _activity = a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          sel ? AppColors.primary : AppColors.divider,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(a.icon,
                          size: 18,
                          color: sel
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.label,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              a.description,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sel)
                        PhosphorIcon(PhosphorIcons.checkCircle(),
                            size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),

            // ── Dietary Preferences ──
            _SheetSection(title: 'DIETARY PREFERENCES'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietOptions.map((opt) {
                final sel = _dietPrefs.contains(opt);
                return GestureDetector(
                  onTap: () => _toggleDiet(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            sel ? AppColors.primary : AppColors.divider,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            Obx(() => GradientButton(
                  text: 'Save Changes',
                  isLoading: widget.ctrl.isSaving.value,
                  onPressed:
                      widget.ctrl.isSaving.value ? null : _save,
                  icon: PhosphorIcon(
                    PhosphorIcons.floppyDisk(),
                    color: Colors.white,
                    size: 18,
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Sheet helpers ─────────────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String title;
  const _SheetSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        child,
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final String displayValue;
  final ValueChanged<double> onChanged;
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: displayValue,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
            inactiveTrackColor:
                AppColors.primary.withValues(alpha: 0.2),
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: PhosphorIcons.minus(),
          onTap: value > min ? onDecrement : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _StepBtn(
          icon: PhosphorIcons.plus(),
          onTap: value < max ? onIncrement : null,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final PhosphorIconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: PhosphorIcon(
            icon,
            size: 16,
            color: onTap != null
                ? AppColors.primary
                : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
