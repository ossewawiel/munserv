import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/form_error_banner.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('FormErrorBanner', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: FormErrorBanner(
            message: 'That phone number is already registered.',
            onDismiss: () {},
            // No entry animation: keeps the golden independent of timing.
            animate: false,
          ),
        ),
        size: const Size(360, 100),
      );

      await expectLater(
        find.byType(FormErrorBanner),
        matchesGoldenFile('goldens/form_error_banner_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: FormErrorBanner(
            message: 'That phone number is already registered.',
            onDismiss: () {},
            animate: false,
          ),
        ),
        dark: true,
        size: const Size(360, 100),
      );

      await expectLater(
        find.byType(FormErrorBanner),
        matchesGoldenFile('goldens/form_error_banner_default_dark.png'),
      );
    });
  });
}
