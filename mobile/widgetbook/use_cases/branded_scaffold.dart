import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/branded_scaffold.dart';
import 'package:munserv_mobile/shared/widgets/munserv_app_bar.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: BrandedScaffold)
Widget brandedScaffold(BuildContext context) {
  final showMapBackground = context.knobs.boolean(
    label: 'Show map background',
    initialValue: true,
  );

  return BrandedScaffold(
    appBar: const MunServAppBar(automaticallyImplyLeading: false),
    showMapBackground: showMapBackground,
    body: const Center(child: Text('Page content')),
  );
}
