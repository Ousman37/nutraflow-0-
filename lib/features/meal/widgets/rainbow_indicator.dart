import 'package:flutter/material.dart';
import '../models/nutrition_analysis.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class RainbowIndicator extends StatelessWidget {
  final List<ColorGroup> colorGroups;

  const RainbowIndicator({super.key, required this.colorGroups});

  static const _colorMap = {
    'Red': Color(0xFFFF6B6B),
    'Orange': Color(0xFFFF9F43),
    'Yellow': Color(0xFFFFD93D),
    'Green': Color(0xFF4CAF82),
    'Blue/Purple': Color(0xFF7B6CF8),
    'White/Brown': Color(0xFFBDAA8A),
  };

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
          Row(
            children: [
              Text('🌈 ', style: const TextStyle(fontSize: 18)),
              Text('Eat the Rainbow', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Food color groups detected in your meal',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colorGroups.map((group) {
              final color = _colorMap[group.color] ?? AppColors.primary;
              return _ColorGroupChip(group: group, color: color);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorGroupChip extends StatelessWidget {
  final ColorGroup group;
  final Color color;

  const _ColorGroupChip({required this.group, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: group.present ? 1.0 : 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: group.present
              ? color.withValues(alpha: 0.12)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: group.present ? color : AppColors.divider,
            width: group.present ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: group.present ? color : AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              group.color,
              style: AppTextStyles.labelSmall.copyWith(
                color: group.present ? color : AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
