import 'package:flutter/material.dart';

import '../../../../shared/models/issue.dart';
import '../../../../shared/theme/typography.dart';
import 'heat_indicator.dart';
import 'issue_state_badge.dart';
import 'issue_type_icon.dart';

/// Display variants for [IssueCard].
enum IssueCardVariant {
  /// Full-width card with large icon. Used in issue lists, my reports, home page.
  list,

  /// Compact card with thumbnail image. Used in map bottom sheet.
  mapPreview,

  /// Minimal card for constrained spaces.
  compact,
}

/// Displays an issue summary in a card format.
///
/// Supports multiple display variants:
/// - [IssueCardVariant.list] - Full-width with icon (default)
/// - [IssueCardVariant.mapPreview] - Compact with thumbnail and close button
/// - [IssueCardVariant.compact] - Minimal information
///
/// ## Usage
/// ```dart
/// // In issue list
/// IssueCard(issue: issue, onTap: () => viewDetail(issue.id))
///
/// // In map bottom sheet
/// IssueCard(
///   issue: issue,
///   variant: IssueCardVariant.mapPreview,
///   onTap: () => viewDetail(issue.id),
///   onClose: () => clearSelection(),
/// )
/// ```
class IssueCard extends StatelessWidget {
  /// The issue to display.
  final IssueSummary issue;

  /// Display variant. Defaults to [IssueCardVariant.list].
  final IssueCardVariant variant;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when close button is tapped (mapPreview variant only).
  final VoidCallback? onClose;

  const IssueCard({
    super.key,
    required this.issue,
    this.variant = IssueCardVariant.list,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      IssueCardVariant.list => _buildListVariant(context),
      IssueCardVariant.mapPreview => _buildMapPreviewVariant(context),
      IssueCardVariant.compact => _buildCompactVariant(context),
    };
  }

  Widget _buildListVariant(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        splashColor: colors.secondary.withValues(alpha: 0.1),
        highlightColor: colors.secondary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Issue type icon
              IssueTypeIcon(
                type: issue.type,
                size: IconSizes.xxl,
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
                        Expanded(
                          child: Text(
                            issue.type.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: IconSizes.sm,
                          color: colors.onSurfaceVariant,
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
                      _formatRelativeDate(issue.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Heat badge
              HeatBadge(heat: issue.heat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreviewVariant(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(Spacing.md),
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
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              // Thumbnail or fallback icon
              _buildThumbnail(colors),
              const SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.type.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: IconSizes.sm,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(
                            '${issue.location.latitude.toStringAsFixed(4)}, ${issue.location.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close button and heat
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      iconSize: IconSizes.md,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(height: Spacing.sm),
                  HeatBadge(heat: issue.heat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactVariant(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              IssueTypeIcon(type: issue.type, size: IconSizes.lg),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  issue.type.displayName,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IssueStateBadge(state: issue.state, compact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colors) {
    final photoUrl = issue.thumbnailUrl;

    return Container(
      width: ThumbnailSizes.md,
      height: ThumbnailSizes.md,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackIcon(colors),
            )
          : _buildFallbackIcon(colors),
    );
  }

  Widget _buildFallbackIcon(ColorScheme colors) {
    return Center(
      child: IssueTypeIcon(
        type: issue.type,
        size: IconSizes.lg,
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes < 1) return 'Just now';
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
