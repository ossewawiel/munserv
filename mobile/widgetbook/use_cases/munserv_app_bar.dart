import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/munserv_app_bar.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: MunServAppBar)
Widget munservAppBar(BuildContext context) {
  final showBackButton = context.knobs.boolean(
    label: 'Show back button',
    initialValue: true,
  );

  return Scaffold(
    appBar: MunServAppBar(automaticallyImplyLeading: showBackButton),
    body: const SizedBox.shrink(),
  );
}
