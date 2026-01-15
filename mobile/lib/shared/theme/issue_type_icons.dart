import 'package:flutter/material.dart';

import '../models/issue_type.dart';

/// Centralized configuration for issue type visual representation
/// Each issue type has a distinctive icon, color, and optional gradient
class IssueTypeVisuals {
  final IconData icon;
  final IconData filledIcon;
  final Color color;
  final Color lightColor;
  final String semanticLabel;

  const IssueTypeVisuals({
    required this.icon,
    required this.filledIcon,
    required this.color,
    required this.lightColor,
    required this.semanticLabel,
  });

  /// Get visuals for an issue type
  static IssueTypeVisuals forType(IssueType type) => _visuals[type]!;

  static const Map<IssueType, IssueTypeVisuals> _visuals = {
    IssueType.pothole: IssueTypeVisuals(
      icon: Icons.warning_amber_rounded,
      filledIcon: Icons.warning_rounded,
      color: Color(0xFFE65100), // Deep Orange
      lightColor: Color(0xFFFFF3E0),
      semanticLabel: 'Pothole hazard',
    ),
    IssueType.waterLeak: IssueTypeVisuals(
      icon: Icons.water_drop_outlined,
      filledIcon: Icons.water_drop,
      color: Color(0xFF0288D1), // Light Blue
      lightColor: Color(0xFFE1F5FE),
      semanticLabel: 'Water leak',
    ),
    IssueType.sewageLeak: IssueTypeVisuals(
      icon: Icons.waves_outlined,
      filledIcon: Icons.waves,
      color: Color(0xFF5D4037), // Brown
      lightColor: Color(0xFFEFEBE9),
      semanticLabel: 'Sewage leak',
    ),
    IssueType.trafficLight: IssueTypeVisuals(
      icon: Icons.traffic_outlined,
      filledIcon: Icons.traffic,
      color: Color(0xFFC62828), // Red
      lightColor: Color(0xFFFFEBEE),
      semanticLabel: 'Traffic light issue',
    ),
    IssueType.streetLight: IssueTypeVisuals(
      icon: Icons.lightbulb_outline,
      filledIcon: Icons.lightbulb,
      color: Color(0xFFF9A825), // Amber
      lightColor: Color(0xFFFFFDE7),
      semanticLabel: 'Street light issue',
    ),
    IssueType.illegalDumping: IssueTypeVisuals(
      icon: Icons.delete_outline,
      filledIcon: Icons.delete,
      color: Color(0xFF2E7D32), // Green (environmental)
      lightColor: Color(0xFFE8F5E9),
      semanticLabel: 'Illegal dumping',
    ),
    IssueType.roadDamage: IssueTypeVisuals(
      icon: Icons.trending_down_outlined,
      filledIcon: Icons.trending_down,
      color: Color(0xFF37474F), // Blue Grey
      lightColor: Color(0xFFECEFF1),
      semanticLabel: 'Road damage',
    ),
    IssueType.other: IssueTypeVisuals(
      icon: Icons.help_outline,
      filledIcon: Icons.help,
      color: Color(0xFF616161), // Grey
      lightColor: Color(0xFFF5F5F5),
      semanticLabel: 'Other issue',
    ),
  };
}
