import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const lime      = Color(0xFFC8FA00);
  static const limeGlow  = Color(0x33C8FA00);
  static const limeDim   = Color(0x12C8FA00);
  static const coral     = Color(0xFFFF6B6B);
  static const blue      = Color(0xFF60A5FA);
  // Dark
  static const darkBg    = Color(0xFF08080E);
  static const darkBg2   = Color(0xFF0E0E1C);
  static const darkGlass = Color(0x08FFFFFF);
  static const darkGlass2= Color(0x12FFFFFF);
  static const darkBorder= Color(0x10FFFFFF);
  static const darkT1    = Color(0xFFFFFFFF);
  static const darkT2    = Color(0xFFA0A0B0);
  static const darkT3    = Color(0xFF505070);
  // Light
  static const lightBg   = Color(0xFFF0F2FF);
  static const lightBg2  = Color(0xFFE6E8F8);
  static const lightGlass= Color(0x90FFFFFF);
  static const lightGlass2=Color(0xCCFFFFFF);
  static const lightBorder=Color(0x12000000);
  static const lightT1   = Color(0xFF0D0D1A);
  static const lightT2   = Color(0xFF4A4A60);
  static const lightT3   = Color(0xFF9090A0);
}

class AppTheme {
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    bg: AppColors.darkBg, bg2: AppColors.darkBg2,
    glass: AppColors.darkGlass, border: AppColors.darkBorder,
    t1: AppColors.darkT1, t2: AppColors.darkT2,
    surface: AppColors.darkBg2,
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    bg: AppColors.lightBg, bg2: AppColors.lightBg2,
    glass: AppColors.lightGlass, border: AppColors.lightBorder,
    t1: AppColors.lightT1, t2: AppColors.lightT2,
    surface: AppColors.lightBg2,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg, required Color bg2,
    required Color glass, required Color border,
    required Color t1, required Color t2, required Color surface,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: AppColors.lime,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.lime, onPrimary: bg,
        secondary: AppColors.blue, onSecondary: bg,
        surface: surface, onSurface: t1,
        error: AppColors.coral, onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: t1),
        headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: t1),
        headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: t1),
        titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: t1),
      ).apply(bodyColor: t1, displayColor: t1),
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: t1)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: glass,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lime, width: 1.5)),
        labelStyle: TextStyle(color: t2), hintStyle: TextStyle(color: t2.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lime, foregroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 54), elevation: 0,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      )),
      cardTheme: CardTheme(color: glass, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: border))),
      useMaterial3: true,
    );
  }
}
