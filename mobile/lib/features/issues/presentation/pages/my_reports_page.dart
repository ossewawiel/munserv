import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
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
            return EmptyState.noReports(
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
