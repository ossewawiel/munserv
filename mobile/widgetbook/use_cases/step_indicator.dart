import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/step_indicator.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _labels = ['Photo', 'Type', 'Location', 'Review'];

@widgetbook.UseCase(name: 'Default', type: StepIndicator)
Widget stepIndicator(BuildContext context) {
  final currentStep = context.knobs.int.slider(
    label: 'Current step',
    initialValue: 1,
    min: 0,
    max: _labels.length - 1,
  );
  final showLabels = context.knobs.boolean(
    label: 'Show labels',
    initialValue: true,
  );

  return StepIndicator(
    totalSteps: _labels.length,
    currentStep: currentStep,
    labels: showLabels ? _labels : null,
  );
}
