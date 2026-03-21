import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme Provider ────────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark; // default
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', newMode == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() => ThemeNotifier());

// ─── Semantic Color Tokens (adaptive) ─────────────────────────────────────────
class AppColors {
  // Dark palette
  static const Color darkBackground    = Color(0xFF0E0E0E);
  static const Color darkSurface       = Color(0xFF131313);
  static const Color darkSurfaceHigh   = Color(0xFF1F2020);
  static const Color darkOnSurface     = Color(0xFFE7E5E5);
  static const Color darkOnSurfaceVar  = Color(0xFFACABAA);
  static const Color darkSecondary     = Color(0xFF9E9E9E);

  // Light palette
  static const Color lightBackground   = Color(0xFFF4F4F5);
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh  = Color(0xFFECECED);
  static const Color lightOnSurface    = Color(0xFF1A1A1A);
  static const Color lightOnSurfaceVar = Color(0xFF6B6B6B);
  static const Color lightSecondary    = Color(0xFF888888);

  // Shared
  static const Color primary           = Color(0xFFC6C6C6);
  static const Color primaryContainer  = Color(0xFF454747);
  static const Color accent            = Color(0xFFFAF9F9);
  static const Color error             = Color(0xFFEE7D77);
  static const Color success           = Color(0xFF4CAF50);
  static const Color warning           = Color(0xFFFF9800);

  static const LinearGradient metallicGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Context-aware helpers
  static Color background(BuildContext context)   => Theme.of(context).brightness == Brightness.dark ? darkBackground   : lightBackground;
  static Color surface(BuildContext context)      => Theme.of(context).brightness == Brightness.dark ? darkSurface      : lightSurface;
  static Color surfaceHigh(BuildContext context)  => Theme.of(context).brightness == Brightness.dark ? darkSurfaceHigh  : lightSurfaceHigh;
  static Color onSurface(BuildContext context)    => Theme.of(context).brightness == Brightness.dark ? darkOnSurface    : lightOnSurface;
  static Color onSurfaceVar(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? darkOnSurfaceVar : lightOnSurfaceVar;
  static Color secondary(BuildContext context)    => Theme.of(context).brightness == Brightness.dark ? darkSecondary    : lightSecondary;
}

// ─── App Themes ────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground   : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface      : AppColors.lightSurface;
    final onSurf  = isDark ? AppColors.darkOnSurface    : AppColors.lightOnSurface;
    final secondary = isDark ? AppColors.darkSecondary  : AppColors.lightSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: const Color(0xFF3F4041),
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primary,
        secondary: secondary,
        onSecondary: bg,
        secondaryContainer: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
        onSecondaryContainer: onSurf,
        surface: surface,
        onSurface: onSurf,
        error: AppColors.error,
        onError: Colors.white,
        surfaceContainerHighest: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
        outline: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.04, color: onSurf),
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: onSurf),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: onSurf),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: onSurf),
        bodyMedium: TextStyle(color: secondary),
        bodySmall: TextStyle(color: secondary),
        labelSmall: TextStyle(color: secondary, letterSpacing: 1),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurf),
        titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5, color: onSurf),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: secondary),
        prefixIconColor: secondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF3F4041),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: secondary,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : secondary),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryContainer : (isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh)),
      ),
    );
  }
}
