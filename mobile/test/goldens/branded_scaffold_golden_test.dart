import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/branded_scaffold.dart';
import 'package:munserv_mobile/shared/widgets/munserv_app_bar.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('BrandedScaffold', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        const BrandedScaffold(
          appBar: MunServAppBar(automaticallyImplyLeading: false),
          body: Center(child: Text('Page content')),
        ),
        size: kGoldenPhoneSize,
      );

      await expectLater(
        find.byType(BrandedScaffold),
        matchesGoldenFile('goldens/branded_scaffold_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        const BrandedScaffold(
          appBar: MunServAppBar(automaticallyImplyLeading: false),
          body: Center(child: Text('Page content')),
        ),
        dark: true,
        size: kGoldenPhoneSize,
      );

      await expectLater(
        find.byType(BrandedScaffold),
        matchesGoldenFile('goldens/branded_scaffold_default_dark.png'),
      );
    });
  });
}
