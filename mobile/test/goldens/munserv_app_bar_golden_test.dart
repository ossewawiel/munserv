import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/munserv_app_bar.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('MunServAppBar', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        Scaffold(appBar: const MunServAppBar(), body: const SizedBox()),
        size: const Size(390, 160),
      );

      await expectLater(
        find.byType(MunServAppBar),
        matchesGoldenFile('goldens/munserv_app_bar_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        Scaffold(appBar: const MunServAppBar(), body: const SizedBox()),
        dark: true,
        size: const Size(390, 160),
      );

      await expectLater(
        find.byType(MunServAppBar),
        matchesGoldenFile('goldens/munserv_app_bar_default_dark.png'),
      );
    });
  });
}
