import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - inspired by truck/fleet industry
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep blue
  static const Color primaryOrange = Color(0xFFEA580C); // Truck orange
  static const Color primaryGreen = Color(0xFF059669); // Success green
  
  // Secondary colors
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color darkBlue = Color(0xFF1E40AF);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Role-specific colors
  static const Color adminColor = Color(0xFF7C3AED); // Purple
  static const Color tripManagerColor = Color(0xFF059669); // Green
  static const Color driverColor = Color(0xFFEA580C); // Orange
  static const Color accountantColor = Color(0xFFDC2626); // Red
  static const Color pumpPartnerColor = Color(0xFF0891B2); // Cyan
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, grey100],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.grey100,
      ),
    );
  }
}
