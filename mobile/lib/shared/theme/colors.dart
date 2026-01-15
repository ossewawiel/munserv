import 'package:flutter/material.dart';

/// Brand colors that can be configured per pod
class BrandColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const BrandColors({
    required this.primary,
    required this.secondary,
    this.tertiary = const Color(0xFFF3EDDA),
  });

  /// Default MunServ brand colors - Forest Green & Terracotta palette
  /// Based on Environmental Emissions App design reference
  static const defaultBrand = BrandColors(
    primary: Color(0xFF233D36), // Forest Green - primary text, outlines
    secondary: Color(0xFFD9613F), // Terracotta - accents, CTAs
    tertiary: Color(0xFFF3EDDA), // Warm Beige - secondary backgrounds
  );

  /// Create brand colors from hex strings
  factory BrandColors.fromHex({
    required String primary,
    required String secondary,
    String? tertiary,
  }) {
    return BrandColors(
      primary: _hexToColor(primary),
      secondary: _hexToColor(secondary),
      tertiary: tertiary != null
          ? _hexToColor(tertiary)
          : const Color(0xFFF3EDDA),
    );
  }

  static Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Surface and background colors for the app
class SurfaceColors {
  /// White/very light background for main scaffold
  static const Color background = Color(0xFFFFFFFF);

  /// Pure white for app bar and navigation
  static const Color white = Color(0xFFFFFFFF);

  /// Cream for card backgrounds (stands out from white)
  static const Color cream = Color(0xFFF3EDDA);

  /// Warm beige for secondary surfaces
  static const Color beige = Color(0xFFF3EDDA);

  /// Dark background for dark theme
  static const Color backgroundDark = Color(0xFF1A1A1A);

  /// Dark surface for dark theme cards
  static const Color surfaceDark = Color(0xFF2D2D2D);
}

/// Text colors
class TextColors {
  /// Primary text color - forest green for light theme
  static const Color primary = Color(0xFF2D4A47);

  /// Secondary text color - slightly lighter
  static const Color secondary = Color(0xFF4A6360);

  /// Muted text color
  static const Color muted = Color(0xFF6B7B78);

  /// White text for dark backgrounds
  static const Color onDark = Color(0xFFFFFFFF);

  /// Dark text for light colored backgrounds
  static const Color onLight = Color(0xFF2D4A47);
}

/// Semantic colors for consistent UI across the app
class SemanticColors {
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
}

/// Issue state colors for visual consistency
class IssueStateColors {
  static const Color reported = Color(0xFFFF9800);
  static const Color confirmed = Color(0xFF2196F3);
  static const Color inProgress = Color(0xFF9C27B0);
  static const Color fixed = Color(0xFF4CAF50);
  static const Color rejected = Color(0xFF9E9E9E);
  static const Color reopened = Color(0xFFF44336);

  static Color fromState(String state) {
    return switch (state) {
      'reported' => reported,
      'confirmed' => confirmed,
      'in_progress' || 'inProgress' => inProgress,
      'fixed' => fixed,
      'rejected' => rejected,
      'reopened' => reopened,
      _ => reported,
    };
  }
}

/// Heat indicator colors (priority visualization)
class HeatColors {
  static const Color low = Color(0xFF4CAF50);
  static const Color medium = Color(0xFFFF9800);
  static const Color high = Color(0xFFF44336);
  static const Color critical = Color(0xFF9C27B0);

  static Color fromHeat(int heat) {
    if (heat >= 80) return critical;
    if (heat >= 60) return high;
    if (heat >= 40) return medium;
    return low;
  }
}

/// Material Design 3 Color Schemes
/// Generated from Material Theme Builder using Forest Green (#233D36) as primary seed,
/// Terracotta (#D9613F) as secondary, and Warm Beige (#F3EDDA) as tertiary.
///
/// These color schemes follow M3's tonal palette system for proper accessibility
/// and consistent visual hierarchy across all components.
class M3ColorSchemes {
  M3ColorSchemes._();

  /// Light color scheme - Forest Green + Terracotta + Beige
  /// All 36 M3 color roles properly calculated from seed colors
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    // Primary - Forest Green tonal
    primary: Color(0xff0c2721),
    surfaceTint: Color(0xff49645c),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xff233d36),
    onPrimaryContainer: Color(0xff8ba89e),
    // Secondary - Terracotta tonal
    secondary: Color(0xffa2391a),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffc35130),
    onSecondaryContainer: Color(0xfffffbff),
    // Tertiary - Beige tonal
    tertiary: Color(0xff615f50),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xfff1edda),
    onTertiaryContainer: Color(0xff6d6b5c),
    // Error
    error: Color(0xffba1a1a),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffffdad6),
    onErrorContainer: Color(0xff93000a),
    // Surface variants
    surface: Color(0xfffaf9f7),
    onSurface: Color(0xff1a1c1b),
    onSurfaceVariant: Color(0xff424846),
    // Outline
    outline: Color(0xff727975),
    outlineVariant: Color(0xffc1c8c4),
    // System
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff2f3130),
    inversePrimary: Color(0xffb0cdc3),
    // Primary fixed
    primaryFixed: Color(0xffcbe9df),
    onPrimaryFixed: Color(0xff05201a),
    primaryFixedDim: Color(0xffb0cdc3),
    onPrimaryFixedVariant: Color(0xff324c44),
    // Secondary fixed
    secondaryFixed: Color(0xffffdbd1),
    onSecondaryFixed: Color(0xff3b0900),
    secondaryFixedDim: Color(0xffffb5a0),
    onSecondaryFixedVariant: Color(0xff852406),
    // Tertiary fixed
    tertiaryFixed: Color(0xffe7e3d0),
    onTertiaryFixed: Color(0xff1d1c11),
    tertiaryFixedDim: Color(0xffcac7b5),
    onTertiaryFixedVariant: Color(0xff49473a),
    // Surface containers (M3 elevation system)
    surfaceDim: Color(0xffdadad8),
    surfaceBright: Color(0xfffaf9f7),
    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xfff4f3f2),
    surfaceContainer: Color(0xffefeeec),
    surfaceContainerHigh: Color(0xffe9e8e6),
    surfaceContainerHighest: Color(0xffe3e2e1),
  );

  /// Dark color scheme - Forest Green + Terracotta + Beige
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    // Primary - Forest Green tonal (dark)
    primary: Color(0xffb0cdc3),
    surfaceTint: Color(0xffb0cdc3),
    onPrimary: Color(0xff1b352e),
    primaryContainer: Color(0xff233d36),
    onPrimaryContainer: Color(0xff8ba89e),
    // Secondary - Terracotta tonal (dark)
    secondary: Color(0xffffb5a0),
    onSecondary: Color(0xff601400),
    secondaryContainer: Color(0xffe76c49),
    onSecondaryContainer: Color(0xff400a00),
    // Tertiary - Beige tonal (dark)
    tertiary: Color(0xffffffff),
    onTertiary: Color(0xff323124),
    tertiaryContainer: Color(0xffe7e3d0),
    onTertiaryContainer: Color(0xff676556),
    // Error
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
    errorContainer: Color(0xff93000a),
    onErrorContainer: Color(0xffffdad6),
    // Surface variants
    surface: Color(0xff121413),
    onSurface: Color(0xffe3e2e1),
    onSurfaceVariant: Color(0xffc1c8c4),
    // Outline
    outline: Color(0xff8b928f),
    outlineVariant: Color(0xff424846),
    // System
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xffe3e2e1),
    inversePrimary: Color(0xff49645c),
    // Primary fixed
    primaryFixed: Color(0xffcbe9df),
    onPrimaryFixed: Color(0xff05201a),
    primaryFixedDim: Color(0xffb0cdc3),
    onPrimaryFixedVariant: Color(0xff324c44),
    // Secondary fixed
    secondaryFixed: Color(0xffffdbd1),
    onSecondaryFixed: Color(0xff3b0900),
    secondaryFixedDim: Color(0xffffb5a0),
    onSecondaryFixedVariant: Color(0xff852406),
    // Tertiary fixed
    tertiaryFixed: Color(0xffe7e3d0),
    onTertiaryFixed: Color(0xff1d1c11),
    tertiaryFixedDim: Color(0xffcac7b5),
    onTertiaryFixedVariant: Color(0xff49473a),
    // Surface containers (M3 elevation system)
    surfaceDim: Color(0xff121413),
    surfaceBright: Color(0xff383938),
    surfaceContainerLowest: Color(0xff0d0e0e),
    surfaceContainerLow: Color(0xff1a1c1b),
    surfaceContainer: Color(0xff1e201f),
    surfaceContainerHigh: Color(0xff292a29),
    surfaceContainerHighest: Color(0xff343534),
  );

  /// Light high contrast scheme for accessibility
  static const ColorScheme lightHighContrast = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff0c2721),
    surfaceTint: Color(0xff49645c),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xff233d36),
    onPrimaryContainer: Color(0xffe4fff5),
    secondary: Color(0xff581200),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xff882708),
    onSecondaryContainer: Color(0xffffffff),
    tertiary: Color(0xff2e2d20),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xff4b4a3c),
    onTertiaryContainer: Color(0xffffffff),
    error: Color(0xff600004),
    onError: Color(0xffffffff),
    errorContainer: Color(0xff98000a),
    onErrorContainer: Color(0xffffffff),
    surface: Color(0xfffaf9f7),
    onSurface: Color(0xff000000),
    onSurfaceVariant: Color(0xff000000),
    outline: Color(0xff272d2b),
    outlineVariant: Color(0xff444b48),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff2f3130),
    inversePrimary: Color(0xffb0cdc3),
    primaryFixed: Color(0xff344e47),
    onPrimaryFixed: Color(0xffffffff),
    primaryFixedDim: Color(0xff1d3731),
    onPrimaryFixedVariant: Color(0xffffffff),
    secondaryFixed: Color(0xff882708),
    onSecondaryFixed: Color(0xffffffff),
    secondaryFixedDim: Color(0xff641600),
    onSecondaryFixedVariant: Color(0xffffffff),
    tertiaryFixed: Color(0xff4b4a3c),
    onTertiaryFixed: Color(0xffffffff),
    tertiaryFixedDim: Color(0xff343326),
    onTertiaryFixedVariant: Color(0xffffffff),
    surfaceDim: Color(0xffb9b9b7),
    surfaceBright: Color(0xfffaf9f7),
    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xfff1f1ef),
    surfaceContainer: Color(0xffe3e2e1),
    surfaceContainerHigh: Color(0xffd5d4d3),
    surfaceContainerHighest: Color(0xffc7c6c5),
  );

  /// Dark high contrast scheme for accessibility
  static const ColorScheme darkHighContrast = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xffd9f7ec),
    surfaceTint: Color(0xffb0cdc3),
    onPrimary: Color(0xff000000),
    primaryContainer: Color(0xffacc9bf),
    onPrimaryContainer: Color(0xff000e0a),
    secondary: Color(0xffffece7),
    onSecondary: Color(0xff000000),
    secondaryContainer: Color(0xffffaf99),
    onSecondaryContainer: Color(0xff1e0300),
    tertiary: Color(0xffffffff),
    onTertiary: Color(0xff000000),
    tertiaryContainer: Color(0xffe7e3d0),
    onTertiaryContainer: Color(0xff2b2a1e),
    error: Color(0xffffece9),
    onError: Color(0xff000000),
    errorContainer: Color(0xffffaea4),
    onErrorContainer: Color(0xff220001),
    surface: Color(0xff121413),
    onSurface: Color(0xffffffff),
    onSurfaceVariant: Color(0xffffffff),
    outline: Color(0xffebf1ee),
    outlineVariant: Color(0xffbdc4c0),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xffe3e2e1),
    inversePrimary: Color(0xff334d46),
    primaryFixed: Color(0xffcbe9df),
    onPrimaryFixed: Color(0xff000000),
    primaryFixedDim: Color(0xffb0cdc3),
    onPrimaryFixedVariant: Color(0xff001510),
    secondaryFixed: Color(0xffffdbd1),
    onSecondaryFixed: Color(0xff000000),
    secondaryFixedDim: Color(0xffffb5a0),
    onSecondaryFixedVariant: Color(0xff290400),
    tertiaryFixed: Color(0xffe7e3d0),
    onTertiaryFixed: Color(0xff000000),
    tertiaryFixedDim: Color(0xffcac7b5),
    onTertiaryFixedVariant: Color(0xff121207),
    surfaceDim: Color(0xff121413),
    surfaceBright: Color(0xff4f504f),
    surfaceContainerLowest: Color(0xff000000),
    surfaceContainerLow: Color(0xff1e201f),
    surfaceContainer: Color(0xff2f3130),
    surfaceContainerHigh: Color(0xff3a3c3b),
    surfaceContainerHighest: Color(0xff464746),
  );

  /// Get color scheme for given brightness
  static ColorScheme getScheme(Brightness brightness) {
    return brightness == Brightness.light ? light : dark;
  }

  /// Get high contrast scheme for given brightness
  static ColorScheme getHighContrastScheme(Brightness brightness) {
    return brightness == Brightness.light
        ? lightHighContrast
        : darkHighContrast;
  }
}
