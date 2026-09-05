import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/empty_state.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  final factories = <String, EmptyState Function()>{
    'no_issues': () => EmptyState.noIssues(onRefresh: () {}),
    'no_reports': () => EmptyState.noReports(onReport: () {}),
    'no_results': () =>
        EmptyState.noResults(query: 'blocked drain', onClear: () {}),
    'network_error': () => EmptyState.networkError(onRetry: () {}),
    'location_error': () => EmptyState.locationError(onRetry: () {}),
  };

  group('EmptyState', () {
    for (final entry in factories.entries) {
      testWidgets('${entry.key} light', (tester) async {
        await pumpGolden(tester, entry.value(), size: const Size(360, 460));

        await expectLater(
          find.byType(EmptyState),
          matchesGoldenFile('goldens/empty_state_${entry.key}_light.png'),
        );
      });

      testWidgets('${entry.key} dark', (tester) async {
        await pumpGolden(
          tester,
          entry.value(),
          dark: true,
          size: const Size(360, 460),
        );

        await expectLater(
          find.byType(EmptyState),
          matchesGoldenFile('goldens/empty_state_${entry.key}_dark.png'),
        );
      });
    }
  });
}
