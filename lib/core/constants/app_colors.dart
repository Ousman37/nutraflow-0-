import 'package:flutter/material.dart';

class AppColors {
  // Brand greens — from logo palette
  static const Color primary = Color(0xFF269D4B);       // #269D4B dark green
  static const Color primaryDark = Color(0xFF1A7A38);   // deeper green
  static const Color secondary = Color(0xFF56C271);     // #56C271 medium green
  static const Color accent = Color(0xFFA8E063);        // #A8E063 light lime

  // Backgrounds
  static const Color background = Color(0xFFF5F7F6);   // #F5F7F6 near-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFEDF5EF);    // very light green tint

  // Text
  static const Color textPrimary = Color(0xFF0D1111);  // #0D1111 near-black
  static const Color textSecondary = Color(0xFF4A6350); // muted green-grey
  static const Color textHint = Color(0xFF9AB8A1);     // soft green hint

  // Status
  static const Color success = Color(0xFF269D4B);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE53E3E);

  // Macros
  static const Color proteinColor = Color(0xFF269D4B);
  static const Color carbsColor = Color(0xFFA8E063);
  static const Color fatColor = Color(0xFFF5A623);
  static const Color fiberColor = Color(0xFF56C271);

  // Divider
  static const Color divider = Color(0xFFDEEDE3);

  // Gradients — hero greens used on dashboard header & splash
  static const List<Color> primaryGradient = [
    Color(0xFF269D4B),
    Color(0xFF56C271),
  ];

  static const List<Color> scoreGradient = [
    Color(0xFFA8E063),
    Color(0xFF269D4B),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFF5A623),
    Color(0xFFE53E3E),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF0F8F3),
  ];

  // Dashboard header gradient — rich dark green
  static const List<Color> dashboardGradient = [
    Color(0xFF1A7A38),
    Color(0xFF0D3B1E),
  ];

  static const List<Color> onboardingBlueGradient = [
    Color(0xFF269D4B),
    Color(0xFF1A7A38),
  ];

  // Dark nav bar background — near-black with green tint
  static const Color navBarDark = Color(0xFF0D1111);
}
