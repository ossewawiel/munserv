import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// A tappable card for quick actions on the home screen.
///
/// The card uses the default card color with the icon displayed in a
/// circular container with the accent color at 10% opacity.
///
/// ## Usage
/// ```dart
/// QuickActionCard(
///   icon: Icons.report,
///   label: 'Report Issue',
///   color: theme.colorScheme.primary,
///   onTap: () => navigateToReport(),
/// )
/// ```
class QuickActionCard extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text below icon.
  final String label;

  /// Accent color for icon and its circular background.
  final Color color;

  /// Called when card is tapped.
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: IconSizes.lg),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
