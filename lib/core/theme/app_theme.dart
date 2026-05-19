// app_theme.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

const String _font = 'PlusJakartaSans';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _font,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: _font, fontSize: 36, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(fontFamily: _font, fontSize: 30, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400, height: 1.55),
        bodyMedium: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w400, height: 1.55),
        bodySmall: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: _font,
          color: AppColors.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
