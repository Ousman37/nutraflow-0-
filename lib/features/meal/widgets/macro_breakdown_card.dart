import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/nutrition_analysis.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MacroBreakdownCard extends StatelessWidget {
  final NutritionAnalysis nutrition;

  const MacroBreakdownCard({super.key, required this.nutrition});

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
          Text('Macro Breakdown', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MacroCircle(
                  label: 'Protein',
                  value: nutrition.proteinG,
                  percent: nutrition.proteinPercent,
                  color: AppColors.proteinColor,
                  unit: 'g',
                  icon: PhosphorIcons.fish(),
                ),
              ),
              Expanded(
                child: _MacroCircle(
                  label: 'Carbs',
                  value: nutrition.carbsG,
                  percent: nutrition.carbsPercent,
                  color: AppColors.carbsColor,
                  unit: 'g',
                  icon: PhosphorIcons.grains(),
                ),
              ),
              Expanded(
                child: _MacroCircle(
                  label: 'Fat',
                  value: nutrition.fatG,
                  percent: nutrition.fatPercent,
                  color: AppColors.fatColor,
                  unit: 'g',
                  icon: PhosphorIcons.drop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CalorieRow(nutrition: nutrition),
          const SizedBox(height: 16),
          if (nutrition.fiberG > 0)
            _FiberRow(fiber: nutrition.fiberG),
        ],
      ),
    );
  }
}

class _MacroCircle extends StatelessWidget {
  final String label;
  final double value;
  final double percent;
  final Color color;
  final String unit;
  final PhosphorIconData icon;

  const _MacroCircle({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PhosphorIcon(icon, size: 20, color: color.withValues(alpha: 0.75)),
        const SizedBox(height: 6),
        SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  '${(percent * 100).round()}%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.round()}$unit',
          style: AppTextStyles.labelLarge.copyWith(color: color),
        ),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _CalorieRow extends StatelessWidget {
  final NutritionAnalysis nutrition;
  const _CalorieRow({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIcons.flame(), size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Total Calories',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          Text(
            '${nutrition.calories.round()} kcal',
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FiberRow extends StatelessWidget {
  final double fiber;
  const _FiberRow({required this.fiber});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            PhosphorIcon(PhosphorIcons.leaf(), size: 16, color: AppColors.fiberColor),
            const SizedBox(width: 8),
            Text('Fiber', style: AppTextStyles.labelMedium),
          ],
        ),
        Text(
          '${fiber.round()}g',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.fiberColor),
        ),
      ],
    );
  }
}
