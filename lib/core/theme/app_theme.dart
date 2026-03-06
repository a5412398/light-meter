import 'package:flutter/material.dart';

class AppTheme {
  // 主色调
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color softGreen = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);

  // 辅助色
  static const Color warmAmber = Color(0xFFFF8F00);
  static const Color softWhite = Color(0xFFFAFAFA);
  static const Color earthBrown = Color(0xFF5D4037);
  static const Color deepCharcoal = Color(0xFF263238);

  // 状态色
  static const Color ideal = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto', // 使用系统字体
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: softWhite,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: lightGreen,
        surface: softWhite,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: deepCharcoal,
        ),
        iconTheme: IconThemeData(color: deepCharcoal),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: deepCharcoal,
        ),
        displayMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: deepCharcoal,
        ),
        displaySmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: deepCharcoal,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: deepCharcoal,
        ),
        titleMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: earthBrown,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: deepCharcoal,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: earthBrown,
        ),
        labelLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: deepCharcoal,
        ),
      ),
    );
  }
}