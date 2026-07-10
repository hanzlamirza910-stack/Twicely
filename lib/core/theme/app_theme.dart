import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Recoleta Alt',
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCardLight,
        error: AppColors.danger,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Recoleta Alt'),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Recoleta Alt'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt'),
        headlineMedium: TextStyle(color: AppColors.textPrimaryLight, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt'),
        titleLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Recoleta Alt'),
        bodyLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontFamily: 'Recoleta Alt'),
        bodyMedium: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14, fontFamily: 'Recoleta Alt'),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Recoleta Alt',
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCardDark,
        error: AppColors.danger,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Recoleta Alt',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontFamily: 'Recoleta Alt'),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Recoleta Alt'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt'),
        headlineMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Recoleta Alt'),
        titleLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Recoleta Alt'),
        bodyLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16, fontFamily: 'Recoleta Alt'),
        bodyMedium: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontFamily: 'Recoleta Alt'),
      ),
    );
  }
}
