import 'package:flutter/material.dart';

import '../models/pod_config.dart';
import 'colors.dart';
import 'typography.dart';

/// M3 Shape Scale with slightly larger radii for approachable feel
class AppShapes {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 16; // Increased from 12
  static const double large = 20; // Increased from 16
  static const double extraLarge = 28;

  static BorderRadius get extraSmallRadius => BorderRadius.circular(extraSmall);
  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);
}

/// Material Design 3 Theme builder
/// Uses M3 tonal palettes from Material Theme Builder for proper accessibility
/// and consistent visual hierarchy.
///
/// M3 Specifications followed:
/// - Buttons: 40dp height, 48dp touch target, stadium shape
/// - Cards: 12dp radius, 1dp elevation
/// - Navigation Bar: 80dp height, pill indicator
/// - Chips: 8dp radius, 32dp height
/// - FAB: 56dp, 16dp radius
/// - Inputs: 4dp radius, filled style
class AppTheme {
  AppTheme._();

  /// Build a complete M3 theme from pod configuration
  static ThemeData buildTheme({
    required PodConfig config,
    required Brightness brightness,
  }) {
    // Use M3 generated color scheme with proper tonal palettes
    final colorScheme = M3ColorSchemes.getScheme(brightness);
    final textTheme = AppTypography.buildTextTheme(brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Custom splash factory for terracotta-tinted feedback
      splashFactory: InkSparkle.splashFactory,
      splashColor: colorScheme.secondary.withValues(alpha: 0.12),
      highlightColor: colorScheme.secondary.withValues(alpha: 0.08),

      // Scaffold - use M3 surface color
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar - M3 style with surface tint
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards - M3: 16dp radius (increased), 1dp elevation, surfaceContainerLow
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.medium), // 16dp
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Input fields - M3: 4dp radius, filled style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4), // M3 extra small shape
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Elevated buttons - M3: 40dp height, 1dp elevation, stadium shape
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              minimumSize: const Size(64, 40), // M3 spec
              elevation: 1,
              backgroundColor: colorScheme.surfaceContainerLow,
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: const StadiumBorder(),
              textStyle: textTheme.labelLarge,
            ).copyWith(
              // Ensure 48dp touch target
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
      ),

      // Filled buttons - M3: 40dp height, primary container, stadium shape
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 40), // M3 spec
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ).copyWith(tapTargetSize: MaterialTapTargetSize.padded),
      ),

      // Outlined buttons - M3: 40dp height, outline, stadium shape
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 40), // M3 spec
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ).copyWith(tapTargetSize: MaterialTapTargetSize.padded),
      ),

      // Text buttons - M3: 40dp height, no background
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 40), // M3 spec
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: textTheme.labelLarge,
        ).copyWith(tapTargetSize: MaterialTapTargetSize.padded),
      ),

      // Icon buttons - M3: 48dp touch target
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          minimumSize: const Size(48, 48), // M3 touch target
        ),
      ),

      // Navigation Bar - M3: 80dp height, pill indicator
      navigationBarTheme: NavigationBarThemeData(
        height: 80, // M3 spec
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // FAB - M3: 56dp, 20dp radius, secondary accent for distinction
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary, // Terracotta
        foregroundColor: colorScheme.onSecondary,
        elevation: 3,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.large), // 20dp
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56, // M3 standard FAB
          height: 56,
        ),
      ),

      // Chips - M3: 8dp radius, 32dp height
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: colorScheme.secondaryContainer,
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // M3 small shape
        ),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),

      // Snackbar - M3: inverseSurface
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // M3 extra small shape
        ),
        elevation: 6,
      ),

      // Divider - M3: outlineVariant
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List tile - M3 spec
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
      ),

      // Icon theme
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),

      // Progress indicator - M3: primary
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Switch - M3 spec
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline;
        }),
      ),

      // Checkbox - M3 spec
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.onSurfaceVariant, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),

      // Radio - M3 spec
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // Dialog - M3 spec
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // M3 extra large shape
        ),
        elevation: 6,
      ),

      // Bottom Sheet - M3 spec
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28), // M3 extra large shape
          ),
        ),
        elevation: 1,
        dragHandleColor: colorScheme.onSurfaceVariant,
        dragHandleSize: const Size(32, 4),
      ),

      // Segmented Button - M3 spec
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.secondaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSecondaryContainer;
            }
            return colorScheme.onSurface;
          }),
          side: WidgetStateProperty.all(BorderSide(color: colorScheme.outline)),
        ),
      ),

      // Slider - M3 spec
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      ),

      // Tab Bar - M3 spec
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleSmall,
      ),

      // Tooltip - M3 spec
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
      ),

      // Badge - M3 spec
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        textStyle: textTheme.labelSmall,
      ),
    );
  }

  /// Light theme using M3 generated colors
  static ThemeData get lightTheme =>
      buildTheme(config: PodConfig.defaultConfig, brightness: Brightness.light);

  /// Dark theme using M3 generated colors
  static ThemeData get darkTheme =>
      buildTheme(config: PodConfig.defaultConfig, brightness: Brightness.dark);
}
