import 'package:flutter/material.dart';

import '../models/pod_config.dart';
import 'colors.dart';
import 'typography.dart';

/// Theme builder that creates Material themes from pod configuration
class AppTheme {
  AppTheme._();

  /// Build a complete theme from pod configuration
  static ThemeData buildTheme({
    required PodConfig config,
    required Brightness brightness,
  }) {
    final brandColors = BrandColors.fromHex(
      primary: config.primaryColor,
      secondary: config.secondaryColor,
      tertiary: config.tertiaryColor,
    );

    final typography = config.fontFamily != null
        ? AppTypography(fontFamily: config.fontFamily!)
        : AppTypography.defaultTypography;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandColors.primary,
      secondary: brandColors.secondary,
      tertiary: brandColors.tertiary,
      error: SemanticColors.error,
      brightness: brightness,
    );

    final textTheme = typography.buildTextTheme(brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgRadius,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: Radii.lgRadius,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm + 4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: Radii.lgRadius,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: Radii.lgRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: Radii.lgRadius,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdRadius,
        ),
      ),
    );
  }

  /// Convenience getter for light theme with default config
  static ThemeData get lightTheme => buildTheme(
        config: PodConfig.defaultConfig,
        brightness: Brightness.light,
      );

  /// Convenience getter for dark theme with default config
  static ThemeData get darkTheme => buildTheme(
        config: PodConfig.defaultConfig,
        brightness: Brightness.dark,
      );
}
