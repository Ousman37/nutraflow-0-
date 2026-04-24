import 'package:flutter/material.dart';
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

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: AppTextStyles.displayMedium),
              const SizedBox(height: 24),
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
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.name,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ctrl.profile?.email ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
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
        _InfoRow(
            label: 'Height', value: '${profile.heightCm.round()} cm'),
        _InfoRow(
            label: 'Weight', value: '${profile.weightKg.round()} kg'),
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

  const _TargetRow({
    required this.label,
    required this.value,
    required this.color,
  });

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
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
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
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icon != null) ...[
                  Icon(icon!, size: 14, color: AppColors.textPrimary),
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
