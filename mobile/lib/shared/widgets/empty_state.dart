import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Empty state display for lists and error conditions.
///
/// Use factory constructors for common scenarios:
/// - [EmptyState.noIssues] - No issues to display
/// - [EmptyState.noReports] - User has no reports
/// - [EmptyState.noResults] - Search returned nothing
/// - [EmptyState.networkError] - Network/connection error
/// - [EmptyState.locationError] - Location permission/service error
///
/// ## Usage
/// ```dart
/// // In issue list
/// if (issues.isEmpty) {
///   return EmptyState.noIssues(
///     onRefresh: () => ref.invalidate(issuesProvider),
///   );
/// }
/// ```
class EmptyState extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Main title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Optional action button.
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// No issues to display.
  factory EmptyState.noIssues({VoidCallback? onRefresh}) {
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: 'No Issues',
      subtitle: 'All clear! No issues have been reported in this area.',
      action: onRefresh != null
          ? OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            )
          : null,
    );
  }

  /// User has no reports.
  factory EmptyState.noReports({VoidCallback? onReport}) {
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Reports Yet',
      subtitle:
          'You haven\'t reported any issues yet. Tap below to report your first issue.',
      action: onReport != null
          ? FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  /// Search returned no results.
  factory EmptyState.noResults({String? query, VoidCallback? onClear}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results',
      subtitle: query != null
          ? 'No issues found matching "$query".'
          : 'No issues match your current filters.',
      action: onClear != null
          ? OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear Filters'),
            )
          : null,
    );
  }

  /// Network or connection error.
  factory EmptyState.networkError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: 'Connection Error',
      subtitle:
          'Unable to connect to the server. Please check your internet connection.',
      action: onRetry != null
          ? FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          : null,
    );
  }

  /// Location permission or service error.
  factory EmptyState.locationError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.location_off,
      title: 'Location Unavailable',
      subtitle: 'Please enable location services to see issues near you.',
      action: onRetry != null
          ? FilledButton(
              onPressed: onRetry,
              child: const Text('Enable Location'),
            )
          : null,
    );
  }

  /// Generic empty state with custom action.
  factory EmptyState.custom({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: onAction != null && actionLabel != null
          ? FilledButton(onPressed: onAction, child: Text(actionLabel))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: IconSizes.display, color: colors.onSurfaceVariant),
            SizedBox(height: Spacing.lg),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[SizedBox(height: Spacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
