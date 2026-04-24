import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool onDarkBackground;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onDarkBackground) {
      // Full-width segmented bars — mint for active, faded white for inactive
      return Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i <= currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 5 : 0),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? const Color(0xFFADE8C8)
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
          );
        }),
      );
    }

    // Light background — compact dot/pill indicator
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final isActive = i <= currentStep;
        final isCurrent = i == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isCurrent ? 28 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: isActive
                ? const LinearGradient(colors: AppColors.primaryGradient)
                : null,
            color: isActive ? null : AppColors.divider,
          ),
        );
      }),
    );
  }
}
