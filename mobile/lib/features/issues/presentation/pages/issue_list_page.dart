import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/issue_providers.dart';
import '../widgets/widgets.dart';

/// Page displaying a filterable list of issues
class IssueListPage extends ConsumerWidget {
  const IssueListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let map background show through
      appBar: AppBar(
        title: const Text('Issues'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/issues/map'),
            tooltip: 'Map View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          const IssueFilterBar(),
          const Divider(height: 1),
          // Issues list
          Expanded(
            child: issuesAsync.when(
              data: (paginated) {
                if (paginated.items.isEmpty) {
                  return EmptyState.noIssues(
                    onRefresh: () => ref.invalidate(issuesProvider),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(issuesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    itemCount: paginated.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == paginated.items.length) {
                        return _PaginationFooter(
                          pagination: paginated.pagination,
                        );
                      }

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
                onRetry: () => ref.invalidate(issuesProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/issues/report'),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Report'),
      ),
    );
  }
}

class _PaginationFooter extends ConsumerWidget {
  final dynamic pagination;

  const _PaginationFooter({required this.pagination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterNotifier = ref.read(issueFilterStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: pagination.page > 1 ? filterNotifier.previousPage : null,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Page ${pagination.page} of ${pagination.totalPages}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: Spacing.sm),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: pagination.page < pagination.totalPages
                ? filterNotifier.nextPage
                : null,
          ),
        ],
      ),
    );
  }
}
