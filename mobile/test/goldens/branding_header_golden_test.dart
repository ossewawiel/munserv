import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/branding_header.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('BrandingHeader', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        const BrandingHeader(),
        size: const Size(390, 100),
      );

      await expectLater(
        find.byType(BrandingHeader),
        matchesGoldenFile('goldens/branding_header_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        const BrandingHeader(),
        dark: true,
        size: const Size(390, 100),
      );

      await expectLater(
        find.byType(BrandingHeader),
        matchesGoldenFile('goldens/branding_header_default_dark.png'),
      );
    });
  });
}
