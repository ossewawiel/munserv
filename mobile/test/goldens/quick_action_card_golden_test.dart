import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/quick_action_card.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  Widget buildCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: QuickActionCard(
        icon: Icons.report_outlined,
        label: 'Report Issue',
        color: colors.primary,
        onTap: () {},
      ),
    );
  }

  group('QuickActionCard', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        Builder(builder: buildCard),
        size: const Size(200, 190),
      );

      await expectLater(
        find.byType(QuickActionCard),
        matchesGoldenFile('goldens/quick_action_card_default_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        Builder(builder: buildCard),
        dark: true,
        size: const Size(200, 190),
      );

      await expectLater(
        find.byType(QuickActionCard),
        matchesGoldenFile('goldens/quick_action_card_default_dark.png'),
      );
    });
  });
}
