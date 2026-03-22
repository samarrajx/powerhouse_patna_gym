import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme Provider ─────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', next == ThemeMode.dark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() => ThemeNotifier());

// ─── App Colors ──────────────────────────────────────────────────────────────
class AppColors {
  // Primary Red Palette
  static const Color primary        = Color(0xFFE53935); // Vivid Red
  static const Color primaryGlow    = Color(0x66E53935); 
  static const Color primaryDim     = Color(0x1AE53935);

  // Dark Theme
  static const Color darkBG         = Color(0xFF0A0A12);
  static const Color darkSurf       = Color(0xFF13131F);
  static const Color darkSurfHigh   = Color(0xFF1C1C2E);
  static const Color darkText1      = Color(0xFFFFFFFF);
  static const Color darkText2      = Color(0xFFA0A0AB);
  static const Color darkText3      = Color(0xFF71717A);

  // Light Theme
  static const Color lightBG        = Color(0xFFF8F9FA);
  static const Color lightSurf      = Color(0xFFFFFFFF);
  static const Color lightSurfHigh  = Color(0xFFF1F3F5);
  static const Color lightText1     = Color(0xFF1A1A1A);
  static const Color lightText2     = Color(0xFF4B5563);
  static const Color lightText3     = Color(0xFF9CA3AF);

  // Glass Effects
  static const Color glassBG        = Color(0x0AFFFFFF);
  static const Color glassBorder    = Color(0x14FFFFFF);
  static const Color glassBG2       = Color(0x14FFFFFF);
  static const Color glassBorder2   = Color(0x26FFFFFF);

  static const Color error          = Color(0xFFFF4B4B);
  static const Color success        = Color(0xFF4CAF50);
  static const Color blue           = Color(0xFF60A5FA);

  static Color bg(BuildContext ctx)      => _isDark(ctx) ? darkBG : lightBG;
  static Color surf(BuildContext ctx)    => _isDark(ctx) ? darkSurf : lightSurf;
  static Color surfHigh(BuildContext ctx) => _isDark(ctx) ? darkSurfHigh : lightSurfHigh;
  static Color text1(BuildContext ctx)   => _isDark(ctx) ? darkText1 : lightText1;
  static Color text2(BuildContext ctx)   => _isDark(ctx) ? darkText2 : lightText2;
  static Color text3(BuildContext ctx)   => _isDark(ctx) ? darkText3 : lightText3;

  static bool _isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── App Themes ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBG : AppColors.lightBG;
    final surf = isDark ? AppColors.darkSurf : AppColors.lightSurf;
    final surfH = isDark ? AppColors.darkSurfHigh : AppColors.lightSurfHigh;
    final t1 = isDark ? AppColors.darkText1 : AppColors.lightText1;
    final t2 = isDark ? AppColors.darkText2 : AppColors.lightText2;
    final t3 = isDark ? AppColors.darkText3 : AppColors.lightText3;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        onSecondary: Colors.white,
        surface: surf,
        onSurface: t1,
        error: AppColors.error,
        onError: Colors.white,
        outline: isDark ? AppColors.glassBorder : Colors.black12,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: TextStyle(fontWeight: FontWeight.w800, color: t1),
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: t1, fontSize: 32),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: t1),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: t1),
        bodyLarge: TextStyle(color: t1),
        bodyMedium: TextStyle(color: t2),
        bodySmall: TextStyle(color: t3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 1.2,
          color: t1,
        ),
        iconTheme: IconThemeData(color: t1),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfH,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: t3, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          elevation: 4,
          shadowColor: AppColors.primaryGlow,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: t3,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.05),
        thickness: 1,
      ),
    );
  }
}
