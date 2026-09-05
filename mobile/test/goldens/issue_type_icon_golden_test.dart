import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_type_icon.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('IssueTypeIcon', () {
    for (final type in IssueType.values) {
      testWidgets('${type.name} light', (tester) async {
        await pumpGolden(
          tester,
          Center(child: IssueTypeIcon(type: type)),
          size: const Size(120, 120),
        );

        await expectLater(
          find.byType(IssueTypeIcon),
          matchesGoldenFile('goldens/issue_type_icon_${type.name}_light.png'),
        );
      });

      testWidgets('${type.name} dark', (tester) async {
        await pumpGolden(
          tester,
          Center(child: IssueTypeIcon(type: type)),
          dark: true,
          size: const Size(120, 120),
        );

        await expectLater(
          find.byType(IssueTypeIcon),
          matchesGoldenFile('goldens/issue_type_icon_${type.name}_dark.png'),
        );
      });
    }
  });
}
