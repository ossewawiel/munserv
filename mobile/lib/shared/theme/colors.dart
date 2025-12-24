import 'package:flutter/material.dart';

/// Brand colors that can be configured per pod
class BrandColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const BrandColors({
    required this.primary,
    required this.secondary,
    this.tertiary = const Color(0xFF6750A4),
  });

  /// Default MunServ brand colors
  static const defaultBrand = BrandColors(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF26A69A),
    tertiary: Color(0xFF6750A4),
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
      tertiary: tertiary != null ? _hexToColor(tertiary) : const Color(0xFF6750A4),
    );
  }

  static Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
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
