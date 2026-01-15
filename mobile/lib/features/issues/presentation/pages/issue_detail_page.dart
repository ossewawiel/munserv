import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/issue_state.dart';
import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/issue_location_map.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/widgets/photo_thumbnail_carousel.dart';
import '../../domain/domain.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Page showing full details of an issue
class IssueDetailPage extends ConsumerWidget {
  final String issueId;

  const IssueDetailPage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueAsync = ref.watch(issueDetailProvider(issueId));

    return BrandedScaffold(
      appBar: AppBar(
        titleSpacing: 0, // Align title closer to back button
        title:
            issueAsync.whenData((issue) {
              final type = IssueType.fromString(issue.type);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IssueTypeIcon(
                    type: type,
                    size: 32, // Compact size with background for AppBar
                    monochrome: true,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(type.displayName),
                ],
              );
            }).value ??
            const Text('Issue Details'),
        actions: [
          // Show state badge in the app bar
          issueAsync.whenData((issue) {
                return Padding(
                  padding: const EdgeInsets.only(right: Spacing.sm),
                  child: Center(
                    child: IssueStateBadge(
                      state: IssueState.fromString(issue.state),
                    ),
                  ),
                );
              }).value ??
              const SizedBox.shrink(),
        ],
      ),
      body: issueAsync.when(
        data: (issue) => _IssueDetailContent(issue: issue),
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(issueDetailProvider(issueId)),
        ),
      ),
    );
  }
}

class _IssueDetailContent extends StatelessWidget {
  final IssueDetail issue;

  const _IssueDetailContent({required this.issue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.md),

          // Map preview
          IssueLocationMap(
            latitude: issue.latitude,
            longitude: issue.longitude,
            onTap: () => context.push('/issues/${issue.id}/map'),
          ),

          const SizedBox(height: Spacing.md),

          // Photo carousel
          PhotoThumbnailCarousel(
            photoUrls: issue.photoUrls,
            onPhotoTap: (index) =>
                context.push('/issues/${issue.id}/photos?index=$index'),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description (if available)
                if (issue.description != null) ...[
                  _InfoSection(
                    icon: Icons.description,
                    title: 'Description',
                    content: issue.description!,
                  ),
                  const SizedBox(height: Spacing.lg),
                ],

                // Stats - Reports and Heat cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people,
                        label: 'Reports',
                        value: issue.reportCount.toString(),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department,
                        label: 'Heat',
                        value: issue.heat.toString(),
                        color: HeatColors.fromHeat(issue.heat),
                      ),
                    ),
                  ],
                ),

                // Status Timeline (always show, even if empty it will show reported date)
                const SizedBox(height: Spacing.lg),
                Text('Status History', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                if (issue.stateHistory.isNotEmpty)
                  IssueTimeline(history: issue.stateHistory)
                else
                  // Fallback: show basic reported/updated if no state history
                  _FallbackTimeline(
                    createdAt: issue.createdAt,
                    updatedAt: issue.updatedAt,
                    currentState: issue.state,
                  ),

                // Bottom padding
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(content, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final displayColor = color ?? colors.primary;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(icon, color: displayColor),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: displayColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback timeline when no state history is available.
/// Shows the issue as "Reported" with the created date and current state.
class _FallbackTimeline extends StatelessWidget {
  final DateTime createdAt;
  final DateTime updatedAt;
  final String currentState;

  const _FallbackTimeline({
    required this.createdAt,
    required this.updatedAt,
    required this.currentState,
  });

  @override
  Widget build(BuildContext context) {
    final state = IssueState.fromString(currentState);
    final stateColor = IssueStateColors.fromState(state.name);

    // Show at least the reported state and current state if different
    final showCurrentState = state != IssueState.reported;

    return Column(
      children: [
        // Reported entry
        _TimelineEntry(
          state: 'Reported',
          date: createdAt,
          color: IssueStateColors.fromState('reported'),
          isLast: !showCurrentState,
        ),
        // Current state if different from reported
        if (showCurrentState)
          _TimelineEntry(
            state: state.displayName,
            date: updatedAt,
            color: stateColor,
            isLast: true,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final String state;
  final DateTime date;
  final Color color;
  final bool isLast;

  const _TimelineEntry({
    required this.state,
    required this.date,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: Spacing.sm),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(_formatDateTime(date), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
