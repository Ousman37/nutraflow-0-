import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/macro_bar.dart';

class NutritionSummaryBar extends StatelessWidget {
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;

  const NutritionSummaryBar({
    super.key,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
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
          Text('Macro Summary', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          MacroBar(
            label: 'Protein',
            current: protein,
            target: proteinTarget,
            color: AppColors.proteinColor,
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Carbs',
            current: carbs,
            target: carbsTarget,
            color: AppColors.carbsColor,
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Fat',
            current: fat,
            target: fatTarget,
            color: AppColors.fatColor,
          ),
        ],
      ),
    );
  }
}
