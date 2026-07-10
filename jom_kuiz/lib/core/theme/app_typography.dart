import 'package:flutter/material.dart';

/// Text style definitions for Jom Kuiz.
///
/// Uses the platform default font family for now. Swap [fontFamily] once
/// brand fonts are added under `assets/fonts/` and declared in `pubspec.yaml`.
abstract final class AppTypography {
  static const String? fontFamily = null; // e.g. 'JomKuiz' once fonts are added

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700, height: 1.12),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, height: 1.16),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.22),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.25),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.29),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.33),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.33),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.45),
  );
}
