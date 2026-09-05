import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/heat_indicator.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  const levels = [0, 25, 50, 75, 100];

  group('HeatIndicator', () {
    for (final heat in levels) {
      testWidgets('heat $heat light', (tester) async {
        await pumpGolden(
          tester,
          HeatIndicator(heat: heat),
          size: const Size(120, 100),
        );

        await expectLater(
          find.byType(HeatIndicator),
          matchesGoldenFile('goldens/heat_indicator_${heat}_light.png'),
        );
      });

      testWidgets('heat $heat dark', (tester) async {
        await pumpGolden(
          tester,
          HeatIndicator(heat: heat),
          dark: true,
          size: const Size(120, 100),
        );

        await expectLater(
          find.byType(HeatIndicator),
          matchesGoldenFile('goldens/heat_indicator_${heat}_dark.png'),
        );
      });
    }
  });
}
