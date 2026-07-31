import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fingerprint_app/app/theme/app_colors.dart';

abstract final class AppTheme {
  static TextTheme _textTheme(Brightness brightness) {
    final base = GoogleFonts.cairoTextTheme();
    final color = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    return base.apply(bodyColor: color, displayColor: color);
  }

  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceMuted,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.info,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.background,
      surfaceContainerHighest: AppColors.surfaceMuted,
    );

    return _base(
      brightness: Brightness.light,
      scheme: scheme,
      scaffold: AppColors.background,
      card: AppColors.surface,
      border: AppColors.border,
      inputFill: AppColors.surface,
      snackBg: AppColors.primaryDark,
      muted: AppColors.surfaceMuted,
      label: AppColors.textSecondary,
      appBarBg: AppColors.surface,
      appBarFg: AppColors.textPrimary,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.darkSurfaceMuted,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.darkTextPrimary,
      secondaryContainer: const Color(0xFF3A3218),
      onSecondaryContainer: AppColors.accentSoft,
      tertiary: AppColors.info,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: const Color(0xFFEF9A9A),
      onError: AppColors.darkBackground,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      surfaceContainerLowest: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkBackground,
      surfaceContainerHighest: AppColors.darkSurfaceMuted,
    );

    return _base(
      brightness: Brightness.dark,
      scheme: scheme,
      scaffold: AppColors.darkBackground,
      card: AppColors.darkSurface,
      border: AppColors.darkBorder,
      inputFill: AppColors.darkSurfaceMuted,
      snackBg: AppColors.darkSurfaceMuted,
      muted: AppColors.darkSurfaceMuted,
      label: AppColors.darkTextSecondary,
      appBarBg: AppColors.darkSurface,
      appBarFg: AppColors.darkTextPrimary,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color border,
    required Color inputFill,
    required Color snackBg,
    required Color muted,
    required Color label,
    required Color appBarBg,
    required Color appBarFg,
  }) {
    final textTheme = _textTheme(brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: appBarFg,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        labelStyle: GoogleFonts.cairo(color: label),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBg,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.sidebar,
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: Color(0xFFB7CBC4)),
        selectedLabelTextStyle: TextStyle(color: Colors.white),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFFB7CBC4)),
        indicatorColor: AppColors.primaryLight,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.sidebar),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: GoogleFonts.cairo(fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
