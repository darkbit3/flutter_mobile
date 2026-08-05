import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Shmeta brand palette ──────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Core
  static const Color dark       = Color(0xFF1C1C1C); // near-black (primary)
  static const Color gold       = Color(0xFFC8A96E); // champagne gold (accent)
  static const Color cream      = Color(0xFFF5EDE0); // light cream surface
  static const Color background = Color(0xFFF0E6D6); // warm sand background
  static const Color border     = Color(0xFFE8D9C5); // warm border
  static const Color textDark   = Color(0xFF1C1C1C);
  static const Color textMid    = Color(0xFF8A7060);
  static const Color textLight  = Color(0xFFA09080);
  static const Color goldLight  = Color(0x26C8A96E); // gold @ 15% opacity
  static const Color darkLight  = Color(0x1A1C1C1C); // dark @ 10% opacity

  // Semantic
  static const Color success    = Color(0xFF10B981);
  static const Color error      = Color(0xFFEF4444);
  static const Color warning    = Color(0xFFF59E0B);
}

// ── Theme builder ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    const gold = AppColors.gold;
    const dark = AppColors.dark;

    const colorScheme = ColorScheme(
      brightness:       Brightness.light,
      primary:          dark,
      onPrimary:        AppColors.cream,
      primaryContainer: AppColors.goldLight,
      onPrimaryContainer: dark,
      secondary:        gold,
      onSecondary:      dark,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: dark,
      surface:          Colors.white,
      onSurface:        dark,
      error:            AppColors.error,
      onError:          Colors.white,
    );
    return ThemeData(
      useMaterial3:        true,
      colorScheme:         colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily:          'sans-serif',

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:  dark,
        foregroundColor:  AppColors.cream,
        elevation:        0,
        centerTitle:      false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:            dark,
          statusBarIconBrightness:   Brightness.light,
          statusBarBrightness:       Brightness.dark,
        ),
      ),

      // ── Bottom nav ───────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:     Colors.white,
        indicatorColor:      AppColors.goldLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.gold);
          }
          return const IconThemeData(color: AppColors.textLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.dark, fontWeight: FontWeight.w700,
              fontSize: 11,
            );
          }
          return const TextStyle(color: AppColors.textLight, fontSize: 11);
        }),
      ),

      // ── Drawer ───────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: dark,
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ── Input decoration ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: const Color(0xFFFAF6F0),
        labelStyle: const TextStyle(color: AppColors.textMid),
        hintStyle:  TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
        prefixIconColor: gold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Filled button ────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark,
          foregroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),

      // ── Outlined button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),

      // ── Elevated button ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark,
          foregroundColor: AppColors.cream,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.goldLight,
        labelStyle: const TextStyle(color: AppColors.dark, fontSize: 12),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark,
        contentTextStyle: const TextStyle(color: AppColors.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
