import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_card.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'fixtures.dart';
import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('IssueCard list', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        IssueCard(issue: Fixtures.issueSummary()),
        size: const Size(390, 170),
      );

      await expectLater(
        find.byType(IssueCard),
        matchesGoldenFile('goldens/issue_card_list_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        IssueCard(issue: Fixtures.issueSummary()),
        dark: true,
        size: const Size(390, 170),
      );

      await expectLater(
        find.byType(IssueCard),
        matchesGoldenFile('goldens/issue_card_list_dark.png'),
      );
    });
  });

  group('IssueCard mapPreview', () {
    testWidgets('light', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpGolden(
          tester,
          IssueCard(
            issue: Fixtures.issueSummary(),
            variant: IssueCardVariant.mapPreview,
            onClose: () {},
          ),
          size: const Size(390, 190),
        );

        await expectLater(
          find.byType(IssueCard),
          matchesGoldenFile('goldens/issue_card_map_preview_light.png'),
        );
      });
    });

    testWidgets('dark', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpGolden(
          tester,
          IssueCard(
            issue: Fixtures.issueSummary(),
            variant: IssueCardVariant.mapPreview,
            onClose: () {},
          ),
          dark: true,
          size: const Size(390, 190),
        );

        await expectLater(
          find.byType(IssueCard),
          matchesGoldenFile('goldens/issue_card_map_preview_dark.png'),
        );
      });
    });
  });

  group('IssueCard compact', () {
    testWidgets('light', (tester) async {
      await pumpGolden(
        tester,
        IssueCard(
          issue: Fixtures.issueSummary(),
          variant: IssueCardVariant.compact,
        ),
        size: const Size(390, 80),
      );

      await expectLater(
        find.byType(IssueCard),
        matchesGoldenFile('goldens/issue_card_compact_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await pumpGolden(
        tester,
        IssueCard(
          issue: Fixtures.issueSummary(),
          variant: IssueCardVariant.compact,
        ),
        dark: true,
        size: const Size(390, 80),
      );

      await expectLater(
        find.byType(IssueCard),
        matchesGoldenFile('goldens/issue_card_compact_dark.png'),
      );
    });
  });
}
