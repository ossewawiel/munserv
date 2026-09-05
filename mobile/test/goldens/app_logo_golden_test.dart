import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/app_logo.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('AppLogo', () {
    testWidgets('small light', (tester) async {
      await pumpGolden(
        tester,
        const Center(child: AppLogo.small()),
        size: const Size(200, 100),
      );

      await expectLater(
        find.byType(AppLogo),
        matchesGoldenFile('goldens/app_logo_small_light.png'),
      );
    });

    testWidgets('small dark', (tester) async {
      await pumpGolden(
        tester,
        const Center(child: AppLogo.small()),
        dark: true,
        size: const Size(200, 100),
      );

      await expectLater(
        find.byType(AppLogo),
        matchesGoldenFile('goldens/app_logo_small_dark.png'),
      );
    });

    testWidgets('large light', (tester) async {
      await pumpGolden(
        tester,
        const Center(child: AppLogo.large()),
        size: const Size(300, 150),
      );

      await expectLater(
        find.byType(AppLogo),
        matchesGoldenFile('goldens/app_logo_large_light.png'),
      );
    });

    testWidgets('large dark', (tester) async {
      await pumpGolden(
        tester,
        const Center(child: AppLogo.large()),
        dark: true,
        size: const Size(300, 150),
      );

      await expectLater(
        find.byType(AppLogo),
        matchesGoldenFile('goldens/app_logo_large_dark.png'),
      );
    });
  });
}
