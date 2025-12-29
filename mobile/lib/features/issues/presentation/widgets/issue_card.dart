import 'package:flutter/material.dart';

import '../../../../shared/models/issue.dart';
import '../../../../shared/theme/typography.dart';
import 'heat_indicator.dart';
import 'issue_state_badge.dart';
import 'issue_type_badge.dart';

/// Card displaying an issue summary in a list
class IssueCard extends StatelessWidget {
  final IssueSummary issue;
  final VoidCallback? onTap;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Image.network(
                  issue.thumbnailUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type and state row
                    Row(
                      children: [
                        IssueTypeBadge(type: issue.type),
                        const SizedBox(width: Spacing.sm),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    // Location placeholder
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(
                            '${issue.location.latitude.toStringAsFixed(4)}, ${issue.location.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    // Date
                    Text(
                      _formatDate(issue.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Heat indicator
              HeatBadge(heat: issue.heat),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
