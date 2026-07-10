import 'package:flutter/material.dart';

/// Centralized color palette for Jom Kuiz.
///
/// Keep raw color values here only. Semantic usage (e.g. "primary button
/// background") belongs in [AppTheme] / [ColorScheme], not here.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2E7D32); // Malaysian-green, warm & trustworthy
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  static const Color secondary = Color(0xFFFFB300); // Playful amber accent for kids/education
  static const Color secondaryLight = Color(0xFFFFE54C);
  static const Color secondaryDark = Color(0xFFC68400);

  // Neutrals
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimaryLight = Color(0xFF1B1B1B);
  static const Color textSecondaryLight = Color(0xFF5F5F5F);
  static const Color textPrimaryDark = Color(0xFFF2F2F2);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2C2C2C);
}
