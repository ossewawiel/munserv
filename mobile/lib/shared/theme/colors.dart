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
    primary: Color(0xFF233D36),   // Forest Green - primary text, outlines
    secondary: Color(0xFFD9613F), // Terracotta - accents, CTAs
    tertiary: Color(0xFFF3EDDA),  // Warm Beige - secondary backgrounds
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
      tertiary: tertiary != null ? _hexToColor(tertiary) : const Color(0xFFF3EDDA),
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
