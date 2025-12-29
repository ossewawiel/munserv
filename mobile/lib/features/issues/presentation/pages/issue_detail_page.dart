import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/issue_state.dart';
import '../../../../shared/models/issue_type.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';
import '../../domain/domain.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Page showing full details of an issue
class IssueDetailPage extends ConsumerWidget {
  final String issueId;

  const IssueDetailPage({
    super.key,
    required this.issueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueAsync = ref.watch(issueDetailProvider(issueId));
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.issueDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
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
          // Photo carousel
          _PhotoCarousel(photoUrls: issue.photoUrls),

          // Main content
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and State
                Row(
                  children: [
                    IssueTypeBadge(type: _parseIssueType(issue.type)),
                    const SizedBox(width: Spacing.sm),
                    IssueStateBadge(state: _parseIssueState(issue.state)),
                    const Spacer(),
                    HeatIndicator(heat: issue.heat),
                  ],
                ),
                const SizedBox(height: Spacing.lg),

                // Location
                _InfoSection(
                  icon: Icons.location_on,
                  title: 'Location',
                  content: issue.address ??
                      '${issue.latitude.toStringAsFixed(6)}, ${issue.longitude.toStringAsFixed(6)}',
                ),

                // Description
                if (issue.description != null) ...[
                  const SizedBox(height: Spacing.md),
                  _InfoSection(
                    icon: Icons.description,
                    title: 'Description',
                    content: issue.description!,
                  ),
                ],

                // Stats
                const SizedBox(height: Spacing.md),
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

                // Timestamps
                const SizedBox(height: Spacing.lg),
                _TimestampInfo(
                  createdAt: issue.createdAt,
                  updatedAt: issue.updatedAt,
                ),

                // State history
                if (issue.stateHistory.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Status History',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  _StateHistoryList(history: issue.stateHistory),
                ],

                // Bottom padding
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IssueType _parseIssueType(String type) {
    return switch (type) {
      'pothole' => IssueType.pothole,
      'water_leak' => IssueType.waterLeak,
      'sewage_leak' => IssueType.sewageLeak,
      'traffic_light' => IssueType.trafficLight,
      'street_light' => IssueType.streetLight,
      'illegal_dumping' => IssueType.illegalDumping,
      _ => IssueType.other,
    };
  }

  IssueState _parseIssueState(String state) {
    return switch (state) {
      'reported' => IssueState.reported,
      'confirmed' => IssueState.confirmed,
      'in_progress' => IssueState.inProgress,
      'fixed' => IssueState.fixed,
      'rejected' => IssueState.rejected,
      _ => IssueState.reported,
    };
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<String> photoUrls;

  const _PhotoCarousel({required this.photoUrls});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.photoUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Image.network(
              widget.photoUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (widget.photoUrls.length > 1)
            Positioned(
              bottom: Spacing.sm,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photoUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
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
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
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
              Text(
                content,
                style: theme.textTheme.bodyMedium,
              ),
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
    final displayColor = color ?? theme.colorScheme.primary;

    return Card(
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
                  Text(
                    label,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimestampInfo extends StatelessWidget {
  final DateTime createdAt;
  final DateTime updatedAt;

  const _TimestampInfo({
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reported',
                style: theme.textTheme.labelSmall,
              ),
              Text(
                _formatDateTime(createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated',
                style: theme.textTheme.labelSmall,
              ),
              Text(
                _formatDateTime(updatedAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StateHistoryList extends StatelessWidget {
  final List<StateHistoryEntry> history;

  const _StateHistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: history.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == history.length - 1;

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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: IssueStateColors.fromState(item.state.name),
                    ),
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
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : Spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.state.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDateTime(item.changedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

