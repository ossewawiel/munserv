import 'package:flutter/material.dart';

import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/typography.dart';

/// Badge displaying the issue type with an icon
class IssueTypeBadge extends StatelessWidget {
  final IssueType type;
  final bool showLabel;
  final double? iconSize;

  const IssueTypeBadge({
    super.key,
    required this.type,
    this.showLabel = true,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? Spacing.sm : Spacing.xs,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(type),
            color: color,
            size: iconSize ?? 16,
          ),
          if (showLabel) ...[
            const SizedBox(width: Spacing.xs),
            Text(
              type.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon(IssueType type) => switch (type) {
        IssueType.pothole => Icons.warning_rounded,
        IssueType.waterLeak => Icons.water_drop,
        IssueType.sewageLeak => Icons.water_damage,
        IssueType.trafficLight => Icons.traffic,
        IssueType.streetLight => Icons.lightbulb,
        IssueType.illegalDumping => Icons.delete,
        IssueType.other => Icons.help_outline,
      };

  Color _getColor(IssueType type) => switch (type) {
        IssueType.pothole => const Color(0xFFE65100),
        IssueType.waterLeak => const Color(0xFF0288D1),
        IssueType.sewageLeak => const Color(0xFF795548),
        IssueType.trafficLight => const Color(0xFFC62828),
        IssueType.streetLight => const Color(0xFFFBC02D),
        IssueType.illegalDumping => const Color(0xFF558B2F),
        IssueType.other => const Color(0xFF757575),
      };
}
