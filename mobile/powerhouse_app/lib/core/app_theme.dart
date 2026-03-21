import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF1F2020);
  static const Color primary = Color(0xFFC6C6C6); // Silver
  static const Color primaryContainer = Color(0xFF454747);
  static const Color secondary = Color(0xFF9E9E9E);
  static const Color accent = Color(0xFFFAF9F9);
  static const Color error = Color(0xFFEE7D77);
  static const Color onSurface = Color(0xFFE7E5E5);
  static const Color onSurfaceVariant = Color(0xFFACABAA);
  
  static const LinearGradient metallicGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Color(0xFF3F4041),
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        secondary: AppColors.secondary,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.04),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
          bodyMedium: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF3F4041),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
