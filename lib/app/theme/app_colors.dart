import 'package:flutter/material.dart';

/// Brand color palette for MECMS admin.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF0B6E4F);
  static const primaryDark = Color(0xFF084C37);
  static const primaryLight = Color(0xFF149C72);
  static const accent = Color(0xFFD4A017);
  static const accentSoft = Color(0xFFFFF4D6);

  // Light neutrals
  static const background = Color(0xFFF3F6F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE8EFEC);
  static const sidebar = Color(0xFF06382E);
  static const sidebarHover = Color(0xFF0A4D3F);
  static const textPrimary = Color(0xFF12241E);
  static const textSecondary = Color(0xFF5B6F67);
  static const border = Color(0xFFD5E0DB);

  // Dark neutrals
  static const darkBackground = Color(0xFF0C1412);
  static const darkSurface = Color(0xFF15201C);
  static const darkSurfaceMuted = Color(0xFF1E2C27);
  static const darkTextPrimary = Color(0xFFE8F0EC);
  static const darkTextSecondary = Color(0xFF9BB0A6);
  static const darkBorder = Color(0xFF2A3B34);

  // Status
  static const success = Color(0xFF1B9E6E);
  static const warning = Color(0xFFE0A800);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF1E88A8);

  static const gradientStart = Color(0xFF0B6E4F);
  static const gradientEnd = Color(0xFF0A4A6E);
}
