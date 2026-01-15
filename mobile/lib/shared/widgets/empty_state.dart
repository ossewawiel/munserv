import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Empty state widget with themed illustration
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  /// No issues found empty state
  factory EmptyState.noIssues({VoidCallback? onReport}) {
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: 'No issues found',
      subtitle:
          'There are no issues matching your filters.\nBe the first to report one!',
      iconColor: const Color(0xFF4CAF50),
      action: onReport != null
          ? FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  /// No reports from user
  factory EmptyState.noReports({VoidCallback? onReport}) {
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No reports yet',
      subtitle:
          'You haven\'t reported any issues yet.\nHelp improve your community!',
      action: onReport != null
          ? FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }

  /// Network error state
  factory EmptyState.networkError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Connection lost',
      subtitle: 'Please check your internet connection and try again.',
      iconColor: const Color(0xFFFF9800),
      action: onRetry != null
          ? OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with decorative background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: effectiveIconColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: Spacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
