import 'package:flutter/material.dart';

import '../models/pod_config.dart';
import 'colors.dart';
import 'typography.dart';

/// Theme builder that creates Material themes from pod configuration
/// Design based on Environmental Emissions App reference
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

    final isLight = brightness == Brightness.light;
    final textTheme = AppTypography.buildTextTheme(brightness: brightness);

    // Color scheme based on design reference:
    // - Forest green for primary text and outlines
    // - Terracotta for accents and CTAs
    // - White background with cream cards
    final colorScheme = ColorScheme(
      brightness: brightness,
      // Primary - Forest Green
      primary: brandColors.primary,
      onPrimary: Colors.white,
      primaryContainer: brandColors.primary,
      onPrimaryContainer: Colors.white,
      // Secondary - Terracotta
      secondary: brandColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: brandColors.secondary,
      onSecondaryContainer: Colors.white,
      // Tertiary - Beige
      tertiary: brandColors.tertiary,
      onTertiary: brandColors.primary,
      tertiaryContainer: SurfaceColors.cream,
      onTertiaryContainer: brandColors.primary,
      // Surfaces
      surface: isLight ? SurfaceColors.cream : SurfaceColors.surfaceDark,
      onSurface: isLight ? brandColors.primary : Colors.white,
      onSurfaceVariant: isLight ? TextColors.secondary : Colors.white70,
      surfaceContainerHighest: isLight ? SurfaceColors.beige : const Color(0xFF3D3D3D),
      // Error
      error: SemanticColors.error,
      onError: Colors.white,
      errorContainer: SemanticColors.errorLight,
      onErrorContainer: SemanticColors.error,
      // Outline - thin forest green
      outline: isLight ? brandColors.primary : Colors.white54,
      outlineVariant: isLight ? brandColors.primary.withValues(alpha: 0.3) : Colors.white24,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Scaffold - white/very light background
      scaffoldBackgroundColor: isLight
          ? SurfaceColors.background
          : SurfaceColors.backgroundDark,

      // AppBar - white, no elevation, forest green text
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? SurfaceColors.white : SurfaceColors.backgroundDark,
        foregroundColor: isLight ? brandColors.primary : Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isLight ? brandColors.primary : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards - cream background, no shadow, rounded corners
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? SurfaceColors.cream : SurfaceColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input fields - outlined with forest green border
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brandColors.primary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brandColors.primary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brandColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: brandColors.primary.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: brandColors.primary),
      ),

      // Elevated buttons - outlined style (forest green border)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: brandColors.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: brandColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Filled buttons - terracotta for CTAs
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined buttons - forest green thin outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandColors.primary,
          side: BorderSide(color: brandColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text buttons - terracotta accent
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Icon buttons - circular outline
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: brandColors.primary,
          side: BorderSide(color: brandColors.primary, width: 1),
          shape: const CircleBorder(),
        ),
      ),

      // Bottom navigation - white background, terracotta selected
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? SurfaceColors.white : SurfaceColors.surfaceDark,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: brandColors.secondary, size: 24);
          }
          return IconThemeData(color: brandColors.primary.withValues(alpha: 0.5), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: brandColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: brandColors.primary.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          );
        }),
      ),

      // FAB - terracotta
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chips - outlined style, pill shape
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: brandColors.primary.withValues(alpha: 0.1),
        side: BorderSide(color: brandColors.primary.withValues(alpha: 0.3)),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: brandColors.primary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Snackbar - forest green
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandColors.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Divider - very subtle
      dividerTheme: DividerThemeData(
        color: isLight ? brandColors.primary.withValues(alpha: 0.1) : Colors.white12,
        thickness: 1,
        space: 1,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        iconColor: brandColors.primary,
        textColor: brandColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: isLight ? brandColors.primary : Colors.white,
        size: 24,
      ),

      // Progress indicator - terracotta
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brandColors.secondary,
        circularTrackColor: brandColors.primary.withValues(alpha: 0.1),
        linearTrackColor: brandColors.primary.withValues(alpha: 0.1),
      ),

      // Switch - terracotta when on
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandColors.secondary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandColors.secondary.withValues(alpha: 0.5);
          }
          return brandColors.primary.withValues(alpha: 0.2);
        }),
      ),

      // Checkbox - forest green
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: brandColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio - forest green
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandColors.primary;
          return brandColors.primary.withValues(alpha: 0.5);
        }),
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
