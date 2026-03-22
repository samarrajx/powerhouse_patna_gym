import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
// Static const values (dark-mode defaults, backwards-compatible)
class AppColors {
  // ── Const palette (dark theme defaults) ─────────────────────────────────
  static const Color background       = Color(0xFF0E0E0E);
  static const Color surface          = Color(0xFF131313);
  static const Color surfaceHigh      = Color(0xFF1F2020);
  static const Color primary          = Color(0xFFC6C6C6);
  static const Color primaryContainer = Color(0xFF454747);
  static const Color secondary        = Color(0xFF9E9E9E);
  static const Color accent           = Color(0xFFFAF9F9);
  static const Color error            = Color(0xFFEE7D77);
  static const Color success          = Color(0xFF4CAF50);
  static const Color warning          = Color(0xFFFF9800);
  static const Color onSurface        = Color(0xFFE7E5E5);
  static const Color onSurfaceVariant = Color(0xFFACABAA);

  static const LinearGradient metallicGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light palette consts ─────────────────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF4F4F5);
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh  = Color(0xFFECECED);
  static const Color lightOnSurface    = Color(0xFF1A1A1A);
  static const Color lightOnSurfaceVar = Color(0xFF6B6B6B);
  static const Color lightSecondary    = Color(0xFF888888);

  // ── Context-aware helpers (use these in non-const widgets) ───────────────
  static Color bg(BuildContext ctx)         => _dark(ctx) ? background         : lightBackground;
  static Color surf(BuildContext ctx)       => _dark(ctx) ? surface            : lightSurface;
  static Color surfH(BuildContext ctx)      => _dark(ctx) ? surfaceHigh        : lightSurfaceHigh;
  static Color onSurf(BuildContext ctx)     => _dark(ctx) ? onSurface          : lightOnSurface;
  static Color onSurfVar(BuildContext ctx)  => _dark(ctx) ? onSurfaceVariant   : lightOnSurfaceVar;
  static Color sec(BuildContext ctx)        => _dark(ctx) ? secondary          : lightSecondary;

  static bool _dark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;
}

// ─── App Themes ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get darkTheme  => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark  = brightness == Brightness.dark;
    final bg      = isDark ? AppColors.background       : AppColors.lightBackground;
    final surf    = isDark ? AppColors.surface          : AppColors.lightSurface;
    final surfH   = isDark ? AppColors.surfaceHigh      : AppColors.lightSurfaceHigh;
    final onSurf  = isDark ? AppColors.onSurface        : AppColors.lightOnSurface;
    final sec     = isDark ? AppColors.secondary        : AppColors.lightSecondary;

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
        secondary: sec,
        onSecondary: bg,
        secondaryContainer: surfH,
        onSecondaryContainer: onSurf,
        surface: surf,
        onSurface: onSurf,
        error: AppColors.error,
        onError: Colors.white,
        surfaceContainerHighest: surfH,
        outline: surfH,
      ),
      textTheme: TextTheme(
        displayLarge:  TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.04, color: onSurf),
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: onSurf),
        headlineMedium:TextStyle(fontWeight: FontWeight.w700, color: onSurf),
        titleLarge:    TextStyle(fontWeight: FontWeight.w600, color: onSurf),
        bodyMedium:    TextStyle(color: sec),
        bodySmall:     TextStyle(color: sec),
        labelSmall:    TextStyle(color: sec, letterSpacing: 1),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurf),
        titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5, color: onSurf),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfH,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: sec),
        prefixIconColor: sec,
        labelStyle: TextStyle(color: sec),
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
        backgroundColor: surf,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: sec,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
      ),
      dividerTheme: DividerThemeData(color: surfH, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : sec),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryContainer : surfH),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surf),
      snackBarTheme: SnackBarThemeData(backgroundColor: surfH, contentTextStyle: TextStyle(color: onSurf)),
    );
  }
}
