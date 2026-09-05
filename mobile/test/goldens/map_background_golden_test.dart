import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/map_background.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('MapBackground', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        const MapBackground(
          child: Center(child: Text('Content over the map background')),
        ),
        size: const Size(360, 240),
      );

      await expectLater(
        find.byType(MapBackground),
        matchesGoldenFile('goldens/map_background_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        const MapBackground(
          child: Center(child: Text('Content over the map background')),
        ),
        dark: true,
        size: const Size(360, 240),
      );

      await expectLater(
        find.byType(MapBackground),
        matchesGoldenFile('goldens/map_background_default_dark.png'),
      );
    });
  });
}
