import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/issue_state.dart';
import '../../../../shared/models/issue_type.dart';
import '../../../../shared/theme/typography.dart';
import '../../domain/domain.dart';
import '../../providers/issue_providers.dart';

/// Filter bar for issue list
class IssueFilterBar extends ConsumerWidget {
  const IssueFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(issueFilterStateProvider);
    final filterNotifier = ref.read(issueFilterStateProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          // State filter
          _FilterChip(
            label: filter.state?.displayName ?? 'All States',
            isActive: filter.state != null,
            onTap: () => _showStateFilter(context, filterNotifier, filter.state),
          ),
          const SizedBox(width: Spacing.sm),
          // Type filter
          _FilterChip(
            label: filter.type?.displayName ?? 'All Types',
            isActive: filter.type != null,
            onTap: () => _showTypeFilter(context, filterNotifier, filter.type),
          ),
          const SizedBox(width: Spacing.sm),
          // Sort by
          _FilterChip(
            label: 'Sort: ${filter.sortBy.displayName}',
            isActive: filter.sortBy != IssueSortBy.heat,
            onTap: () => _showSortOptions(context, filterNotifier, filter.sortBy),
          ),
          // Clear filters button
          if (filter.state != null || filter.type != null) ...[
            const SizedBox(width: Spacing.sm),
            ActionChip(
              label: const Text('Clear'),
              avatar: const Icon(Icons.close, size: 16),
              onPressed: filterNotifier.clearFilters,
            ),
          ],
        ],
      ),
    );
  }

  void _showStateFilter(
    BuildContext context,
    IssueFilterState notifier,
    IssueState? current,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet<IssueState?>(
        title: 'Filter by State',
        options: [null, ...IssueState.values],
        current: current,
        labelBuilder: (state) => state?.displayName ?? 'All States',
        onSelect: (state) {
          notifier.setStateFilter(state);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTypeFilter(
    BuildContext context,
    IssueFilterState notifier,
    IssueType? current,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet<IssueType?>(
        title: 'Filter by Type',
        options: [null, ...IssueType.values],
        current: current,
        labelBuilder: (type) => type?.displayName ?? 'All Types',
        onSelect: (type) {
          notifier.setTypeFilter(type);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSortOptions(
    BuildContext context,
    IssueFilterState notifier,
    IssueSortBy current,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet<IssueSortBy>(
        title: 'Sort by',
        options: IssueSortBy.values,
        current: current,
        labelBuilder: (sort) => sort.displayName,
        onSelect: (sort) {
          notifier.setSortBy(sort);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(
        Icons.arrow_drop_down,
        size: 20,
        color: isActive
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FilterSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T current;
  final String Function(T) labelBuilder;
  final void Function(T) onSelect;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.labelBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ...options.map(
            (option) => ListTile(
              title: Text(labelBuilder(option)),
              trailing: option == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => onSelect(option),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }
}
