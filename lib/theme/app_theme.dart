import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary = Color(0xFF6BB3E0);
  static const Color primaryDark = Color(0xFF4A9AD4);
  static const Color primarySoft = Color(0xFFEAF5FC);
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2A37);
  static const Color shadow = Color(0x33000000);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
