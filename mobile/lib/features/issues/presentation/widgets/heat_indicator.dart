import 'package:flutter/material.dart';

import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';

/// Displays the heat score with visual indicator
class HeatIndicator extends StatelessWidget {
  final int heat;
  final bool showLabel;
  final double size;

  const HeatIndicator({
    super.key,
    required this.heat,
    this.showLabel = true,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = HeatColors.fromHeat(heat);
    final normalizedHeat = heat.clamp(0, 100) / 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: normalizedHeat,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 4,
              ),
              Text(
                heat.toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            'Heat',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact heat badge for use in lists
class HeatBadge extends StatelessWidget {
  final int heat;

  /// When true, uses muted (desaturated) colors for subtle display
  final bool muted;

  const HeatBadge({super.key, required this.heat, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted
        ? HeatColors.fromHeatMuted(heat)
        : HeatColors.fromHeat(heat);

    // Use slightly lower alpha values for muted mode
    final bgAlpha = muted ? 0.08 : 0.1;
    final borderAlpha = muted ? 0.2 : 0.3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: color, size: 14),
          const SizedBox(width: 2),
          Text(
            heat.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
