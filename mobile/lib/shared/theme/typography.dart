import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typography configuration for the app
/// Uses Source Sans 3 throughout for a clean, modern look
class AppTypography {
  AppTypography._();

  /// Build a complete TextTheme using Source Sans 3
  static TextTheme buildTextTheme({Brightness brightness = Brightness.light}) {
    final baseColor = brightness == Brightness.light
        ? TextColors.primary
        : Colors.white;
    final secondaryColor = brightness == Brightness.light
        ? TextColors.secondary
        : Colors.white70;

    return TextTheme(
      // Display styles - Source Sans 3 (large headlines)
      displayLarge: GoogleFonts.sourceSans3(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: baseColor,
      ),
      displayMedium: GoogleFonts.sourceSans3(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      displaySmall: GoogleFonts.sourceSans3(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),

      // Headline styles - Source Sans 3 (section headers)
      headlineLarge: GoogleFonts.sourceSans3(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.sourceSans3(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.sourceSans3(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),

      // Title styles - Source Sans 3
      titleLarge: GoogleFonts.sourceSans3(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.sourceSans3(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: baseColor,
      ),

      // Body styles - Source Sans 3
      bodyLarge: GoogleFonts.sourceSans3(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: secondaryColor,
      ),

      // Label styles - Source Sans 3
      labelLarge: GoogleFonts.sourceSans3(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.sourceSans3(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
    );
  }

  /// Build text style for numbers/data displays
  static TextStyle dataDisplay({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.sourceSans3(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? TextColors.primary,
    );
  }
}

/// Common spacing values for consistent layout
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Common border radius values
class Radii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}
