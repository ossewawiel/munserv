import 'package:flutter/material.dart';

import '../../../../shared/models/issue_state.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';

/// Badge displaying the issue state with appropriate color
class IssueStateBadge extends StatelessWidget {
  final IssueState state;
  final bool compact;

  const IssueStateBadge({
    super.key,
    required this.state,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(state);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.sm : Spacing.md,
        vertical: compact ? 2 : Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Text(
        state.displayName,
        style: (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor(IssueState state) => switch (state) {
        IssueState.reported => IssueStateColors.reported,
        IssueState.confirmed => IssueStateColors.confirmed,
        IssueState.inProgress => IssueStateColors.inProgress,
        IssueState.fixed => IssueStateColors.fixed,
        IssueState.rejected => IssueStateColors.rejected,
      };
}
