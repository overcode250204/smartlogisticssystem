import 'package:flutter/material.dart';

class AppColors {
  static const darkest = Color(0xFFF8FAFC); // slate 50 - page background
  static const sidebar = Colors.white; // sidebar background
  static const card = Colors.white; // card background
  static const primary = Color(0xFF4F46E5); // premium indigo primary color
  static const success = Color(0xFF059669); // emerald 600 - safe green for light theme
  static const warning = Color(0xFFD97706); // amber 600 - rich orange-brown for readability
  static const danger = Color(0xFFDC2626); // red 600 - crisp red
  static const info = Color(0xFF3B82F6); // blue 500 - informational
  static const textPrimary = Color(0xFF0F172A); // slate 900 - very premium primary text
  static const textSecondary = Color(0xFF475569); // slate 600 - professional secondary text
  static const border = Color(0xFFE2E8F0); // slate 200 - clean border line
}

ThemeData buildSmartLogisticsTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.darkest,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.card,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),
    dataTableTheme: const DataTableThemeData(
      headingTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      dataTextStyle: TextStyle(color: AppColors.textPrimary),
      dividerThickness: 0.6,
    ),
  );
}
