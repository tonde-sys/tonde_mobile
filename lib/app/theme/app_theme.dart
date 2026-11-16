import 'package:flutter/material.dart';
import 'package:tonde/app/theme/app_colors.dart';

/// Thèmes Material 3 clair et sombre de l'application.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: isDark ? AppColors.secondary : null,
    );
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamilyFallback: const ['Inter', 'Roboto'],
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}
