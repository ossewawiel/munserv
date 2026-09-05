import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/empty_state.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'No issues', type: EmptyState)
Widget emptyStateNoIssues(BuildContext context) {
  final showAction = context.knobs.boolean(
    label: 'Show refresh action',
    initialValue: true,
  );

  return EmptyState.noIssues(onRefresh: showAction ? () {} : null);
}

@widgetbook.UseCase(name: 'No reports', type: EmptyState)
Widget emptyStateNoReports(BuildContext context) {
  final showAction = context.knobs.boolean(
    label: 'Show report action',
    initialValue: true,
  );

  return EmptyState.noReports(onReport: showAction ? () {} : null);
}

@widgetbook.UseCase(name: 'No results', type: EmptyState)
Widget emptyStateNoResults(BuildContext context) {
  final query = context.knobs.stringOrNull(
    label: 'Search query',
    initialValue: 'blocked drain',
  );
  final showAction = context.knobs.boolean(
    label: 'Show clear action',
    initialValue: true,
  );

  return EmptyState.noResults(query: query, onClear: showAction ? () {} : null);
}

@widgetbook.UseCase(name: 'Network error', type: EmptyState)
Widget emptyStateNetworkError(BuildContext context) {
  final showAction = context.knobs.boolean(
    label: 'Show retry action',
    initialValue: true,
  );

  return EmptyState.networkError(onRetry: showAction ? () {} : null);
}

@widgetbook.UseCase(name: 'Location error', type: EmptyState)
Widget emptyStateLocationError(BuildContext context) {
  final showAction = context.knobs.boolean(
    label: 'Show retry action',
    initialValue: true,
  );

  return EmptyState.locationError(onRetry: showAction ? () {} : null);
}
