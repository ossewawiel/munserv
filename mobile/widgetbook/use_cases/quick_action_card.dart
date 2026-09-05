import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/quick_action_card.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: QuickActionCard)
Widget quickActionCard(BuildContext context) {
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Report Issue',
  );
  final colors = Theme.of(context).colorScheme;

  return SizedBox(
    width: 160,
    child: QuickActionCard(
      icon: Icons.report_outlined,
      label: label,
      color: colors.primary,
      onTap: () {},
    ),
  );
}
