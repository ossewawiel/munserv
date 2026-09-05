import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/form_error_banner.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: FormErrorBanner)
Widget formErrorBanner(BuildContext context) {
  final message = context.knobs.string(
    label: 'Message',
    initialValue: 'That phone number is already registered.',
  );
  final dismissible = context.knobs.boolean(
    label: 'Dismissible',
    initialValue: true,
  );
  final animate = context.knobs.boolean(label: 'Animate', initialValue: false);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: FormErrorBanner(
      message: message,
      onDismiss: dismissible ? () {} : null,
      animate: animate,
    ),
  );
}
