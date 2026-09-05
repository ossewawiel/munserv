import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/error_display.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('ErrorDisplay', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        ErrorDisplay(
          error: 'Something went wrong. Please try again.',
          onRetry: () {},
        ),
        size: const Size(360, 320),
      );

      await expectLater(
        find.byType(ErrorDisplay),
        matchesGoldenFile('goldens/error_display_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        ErrorDisplay(
          error: 'Something went wrong. Please try again.',
          onRetry: () {},
        ),
        dark: true,
        size: const Size(360, 320),
      );

      await expectLater(
        find.byType(ErrorDisplay),
        matchesGoldenFile('goldens/error_display_default_dark.png'),
      );
    });
  });
}
