import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF5B8BFF);
  static const Color primaryDark = Color(0xFF3D6FE8);
  static const Color secondary = Color(0xFF7B6CF8);
  static const Color accent = Color(0xFF00D4AA);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF0F3FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF8B8FA8);
  static const Color textHint = Color(0xFFBDC1D1);

  // Status
  static const Color success = Color(0xFF4CAF82);
  static const Color warning = Color(0xFFFFB443);
  static const Color error = Color(0xFFFF6B6B);

  // Macros
  static const Color proteinColor = Color(0xFF5B8BFF);
  static const Color carbsColor = Color(0xFFFFB443);
  static const Color fatColor = Color(0xFFFF6B9D);
  static const Color fiberColor = Color(0xFF4CAF82);

  // Divider
  static const Color divider = Color(0xFFEEF0F8);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF5B8BFF),
    Color(0xFF7B6CF8),
  ];

  static const List<Color> scoreGradient = [
    Color(0xFF00D4AA),
    Color(0xFF5B8BFF),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFFB443),
    Color(0xFFFF6B9D),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF8F9FF),
  ];

  // Dashboard & onboarding blue gradient (matches reference design)
  static const List<Color> dashboardGradient = [
    Color(0xFF5B8BFF),
    Color(0xFF3D60D8),
  ];

  static const List<Color> onboardingBlueGradient = [
    Color(0xFF5B8BFF),
    Color(0xFF4268E8),
  ];

  // Dark nav bar background
  static const Color navBarDark = Color(0xFF1A2340);
}
