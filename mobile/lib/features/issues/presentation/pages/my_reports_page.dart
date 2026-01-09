import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Page showing issues reported by the current user
class MyReportsPage extends ConsumerWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myIssuesAsync = ref.watch(myIssuesProvider());

    return BrandedScaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: myIssuesAsync.when(
        data: (paginated) {
          if (paginated.items.isEmpty) {
            return _EmptyState(
              onReport: () => context.push('/issues/report'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myIssuesProvider());
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              itemCount: paginated.items.length,
              itemBuilder: (context, index) {
                final issue = paginated.items[index];
                return IssueCard(
                  key: ValueKey(issue.id),
                  issue: issue,
                  onTap: () => context.push('/issues/${issue.id}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(myIssuesProvider()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/issues/report'),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Report'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReport;

  const _EmptyState({required this.onReport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'No reports yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'You haven\'t reported any issues yet.\nHelp improve your community!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Report Issue'),
            ),
          ],
        ),
      ),
    );
  }
}
