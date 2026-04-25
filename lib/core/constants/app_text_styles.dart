import 'package:flutter/material.dart';
import 'app_colors.dart';

const String _font = 'PlusJakartaSans';

class AppTextStyles {
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: _font,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: _font,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: _font,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: _font,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: _font,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.55,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.55,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontFamily: _font,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      );

  static TextStyle get buttonText => const TextStyle(
        fontFamily: _font,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get captionText => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.4,
      );
}
