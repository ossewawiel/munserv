import 'package:flutter/material.dart';

import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/issue_type_icons.dart';

/// Large distinctive icon for issue type display
/// Used in issue cards as an alternative to thumbnail photos
class IssueTypeIcon extends StatelessWidget {
  final IssueType type;
  final double size;
  final bool showBackground;
  final bool filled;

  /// When true, uses primary color instead of per-type colors
  final bool monochrome;

  const IssueTypeIcon({
    super.key,
    required this.type,
    this.size = 56,
    this.showBackground = true,
    this.filled = true,
    this.monochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = IssueTypeVisuals.forType(type);
    final iconSize = size * 0.5;
    final colors = Theme.of(context).colorScheme;

    // Use primary color for monochrome mode, otherwise use per-type color
    final iconColor = monochrome ? colors.primary : visuals.color;
    final backgroundColor = monochrome
        ? colors.primary.withValues(alpha: 0.05)
        : visuals.lightColor;
    final borderColor = monochrome
        ? colors.primary.withValues(alpha: 0.15)
        : visuals.color.withValues(alpha: 0.2);

    if (!showBackground) {
      return Icon(
        filled ? visuals.filledIcon : visuals.icon,
        color: iconColor,
        size: iconSize,
        semanticLabel: visuals.semanticLabel,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.25), // Rounded square
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Icon(
          filled ? visuals.filledIcon : visuals.icon,
          color: iconColor,
          size: iconSize,
          semanticLabel: visuals.semanticLabel,
        ),
      ),
    );
  }
}

/// Circular variant for map markers and compact displays
class IssueTypeIconCircle extends StatelessWidget {
  final IssueType type;
  final double size;
  final bool showBorder;

  const IssueTypeIconCircle({
    super.key,
    required this.type,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = IssueTypeVisuals.forType(type);
    final iconSize = size * 0.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visuals.lightColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: visuals.color.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: visuals.color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(visuals.filledIcon, color: visuals.color, size: iconSize),
      ),
    );
  }
}
