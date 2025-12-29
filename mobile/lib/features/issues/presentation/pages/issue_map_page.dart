import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/issue.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/typography.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Page showing issues on a map
class IssueMapPage extends ConsumerStatefulWidget {
  const IssueMapPage({super.key});

  @override
  ConsumerState<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends ConsumerState<IssueMapPage> {
  IssueSummary? _selectedIssue;

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(allIssuesListProvider);
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapViewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.pop(),
            tooltip: 'List View',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map area
          issuesAsync.when(
            data: (issues) => _MapPlaceholder(
              issues: issues,
              selectedIssue: _selectedIssue,
              onIssueSelected: (issue) => setState(() => _selectedIssue = issue),
            ),
            loading: () => const LoadingSpinner(),
            error: (error, _) => ErrorDisplay(
              error: error,
              onRetry: () => ref.invalidate(allIssuesListProvider),
            ),
          ),

          // Issue detail card (bottom sheet style)
          if (_selectedIssue != null)
            Positioned(
              left: Spacing.md,
              right: Spacing.md,
              bottom: Spacing.md,
              child: _IssuePreviewCard(
                issue: _selectedIssue!,
                onTap: () => context.push('/issues/${_selectedIssue!.id}'),
                onClose: () => setState(() => _selectedIssue = null),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedIssue == null
          ? FloatingActionButton(
              onPressed: () => context.push('/issues/report'),
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }
}

/// Placeholder for actual map implementation
/// TODO: Replace with flutter_map or google_maps_flutter
class _MapPlaceholder extends StatelessWidget {
  final List<IssueSummary> issues;
  final IssueSummary? selectedIssue;
  final void Function(IssueSummary) onIssueSelected;

  const _MapPlaceholder({
    required this.issues,
    required this.selectedIssue,
    required this.onIssueSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          // Map background placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map,
                  size: 100,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Map View',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  '${issues.length} issues',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Issue markers (positioned relatively based on lat/lng)
          ...issues.map((issue) {
            // Simple positioning based on lat/lng for demo
            // In real implementation, this would use map projection
            final x = ((issue.location.longitude + 180) / 360) *
                MediaQuery.of(context).size.width;
            final y = ((90 - issue.location.latitude) / 180) *
                (MediaQuery.of(context).size.height - 200);

            return Positioned(
              left: x.clamp(20, MediaQuery.of(context).size.width - 60).toDouble(),
              top: y.clamp(60, MediaQuery.of(context).size.height - 300).toDouble(),
              child: _MapMarker(
                issue: issue,
                isSelected: selectedIssue?.id == issue.id,
                onTap: () => onIssueSelected(issue),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IssueSummary issue;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapMarker({
    required this.issue,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = HeatColors.fromHeat(issue.heat);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.4 : 0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getTypeIcon(issue.type),
          color: Colors.white,
          size: isSelected ? 24 : 18,
        ),
      ),
    );
  }

  IconData _getTypeIcon(dynamic type) {
    if (type == null) return Icons.help_outline;
    final typeName = type.toString().split('.').last;
    return switch (typeName) {
      'pothole' => Icons.warning_rounded,
      'waterLeak' => Icons.water_drop,
      'sewageLeak' => Icons.water_damage,
      'trafficLight' => Icons.traffic,
      'streetLight' => Icons.lightbulb,
      'illegalDumping' => Icons.delete,
      _ => Icons.help_outline,
    };
  }
}

class _IssuePreviewCard extends StatelessWidget {
  final IssueSummary issue;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _IssuePreviewCard({
    required this.issue,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Image.network(
                  issue.thumbnailUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IssueTypeBadge(type: issue.type),
                        const SizedBox(width: Spacing.sm),
                        IssueStateBadge(state: issue.state, compact: true),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
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
                  ],
                ),
              ),
              // Heat and close
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    iconSize: 20,
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
}
