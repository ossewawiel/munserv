import 'package:flutter/material.dart';

import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/issue_type_icons.dart';
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
    final visuals = IssueTypeVisuals.forType(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? Spacing.sm : Spacing.xs,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: visuals.lightColor,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: visuals.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.filledIcon, color: visuals.color, size: iconSize ?? 16),
          if (showLabel) ...[
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                type.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: visuals.color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
