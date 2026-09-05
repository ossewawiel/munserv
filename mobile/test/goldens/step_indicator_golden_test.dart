import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/step_indicator.dart';

import 'golden_test_helper.dart';

const _labels = ['Photo', 'Type', 'Location', 'Review'];
const _totalSteps = 4;

void main() {
  setUpAll(goldenTestSetUp);

  group('StepIndicator', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        const StepIndicator(
          totalSteps: _totalSteps,
          currentStep: 1,
          labels: _labels,
        ),
        size: const Size(360, 100),
      );

      await expectLater(
        find.byType(StepIndicator),
        matchesGoldenFile('goldens/step_indicator_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        const StepIndicator(
          totalSteps: _totalSteps,
          currentStep: 1,
          labels: _labels,
        ),
        dark: true,
        size: const Size(360, 100),
      );

      await expectLater(
        find.byType(StepIndicator),
        matchesGoldenFile('goldens/step_indicator_default_dark.png'),
      );
    });
  });
}
