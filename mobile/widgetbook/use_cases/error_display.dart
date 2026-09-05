import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/error_display.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: ErrorDisplay)
Widget errorDisplay(BuildContext context) {
  final message = context.knobs.string(
    label: 'Message',
    initialValue: 'Something went wrong. Please try again.',
  );
  final showRetry = context.knobs.boolean(
    label: 'Show retry',
    initialValue: true,
  );

  return ErrorDisplay(error: message, onRetry: showRetry ? () {} : null);
}
