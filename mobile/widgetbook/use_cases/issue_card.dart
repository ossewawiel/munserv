import 'package:flutter/material.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_card.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../fixtures.dart';

@widgetbook.UseCase(name: 'List', type: IssueCard)
Widget issueCardList(BuildContext context) {
  final type = context.knobs.object.dropdown<IssueType>(
    label: 'Type',
    options: IssueType.values,
    labelBuilder: (value) => value.displayName,
  );
  final state = context.knobs.object.dropdown<IssueState>(
    label: 'State',
    options: IssueState.values,
    labelBuilder: (value) => value.displayName,
  );
  final heat = context.knobs.int.slider(
    label: 'Heat',
    initialValue: 45,
    min: 0,
    max: 100,
  );

  return IssueCard(
    issue: Fixtures.issueSummary(type: type, state: state, heat: heat),
  );
}

@widgetbook.UseCase(name: 'Map preview', type: IssueCard)
Widget issueCardMapPreview(BuildContext context) {
  final showClose = context.knobs.boolean(
    label: 'Show close button',
    initialValue: true,
  );

  return IssueCard(
    issue: Fixtures.issueSummary(),
    variant: IssueCardVariant.mapPreview,
    onClose: showClose ? () {} : null,
  );
}

@widgetbook.UseCase(name: 'Compact', type: IssueCard)
Widget issueCardCompact(BuildContext context) {
  return IssueCard(
    issue: Fixtures.issueSummary(),
    variant: IssueCardVariant.compact,
  );
}
