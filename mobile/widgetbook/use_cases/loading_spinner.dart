import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/loading_spinner.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: LoadingSpinner)
Widget loadingSpinner(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 40,
    min: 16,
    max: 96,
  );

  return LoadingSpinner(size: size);
}
