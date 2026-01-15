import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munserv_mobile/features/issues/domain/state_history.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_timeline.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/theme/colors.dart';

void main() {
  group('IssueTimeline', () {
    final testHistory = [
      StateHistoryEntry(
        state: IssueState.reported,
        changedAt: DateTime(2025, 1, 12, 10, 30),
      ),
      StateHistoryEntry(
        state: IssueState.confirmed,
        changedAt: DateTime(2025, 1, 13, 14, 15),
        note: 'Verified by field team',
      ),
    ];

    testWidgets('renders nothing when history is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: []),
          ),
        ),
      );

      // Should render SizedBox.shrink()
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders correct number of timeline entries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: testHistory),
          ),
        ),
      );

      // Should show state display names
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('displays timestamps in correct format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: testHistory),
          ),
        ),
      );

      // Check formatted dates
      expect(find.text('12/1/2025 10:30'), findsOneWidget);
      expect(find.text('13/1/2025 14:15'), findsOneWidget);
    });

    testWidgets('displays notes when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: testHistory),
          ),
        ),
      );

      expect(find.text('Verified by field team'), findsOneWidget);
    });

    testWidgets('displays changedBy when provided', (tester) async {
      final historyWithChanger = [
        StateHistoryEntry(
          state: IssueState.confirmed,
          changedAt: DateTime(2025, 1, 13),
          changedBy: 'Admin User',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: historyWithChanger),
          ),
        ),
      );

      expect(find.text('by Admin User'), findsOneWidget);
    });

    testWidgets('renders colored dot for each state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: testHistory),
          ),
        ),
      );

      // Should have 2 circular containers (timeline dots)
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle)
          .toList();

      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('uses correct colors for issue states', (tester) async {
      final singleEntryHistory = [
        StateHistoryEntry(
          state: IssueState.reported,
          changedAt: DateTime(2025, 1, 12),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: singleEntryHistory),
          ),
        ),
      );

      // Find the circular container (timeline dot)
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle &&
              c.constraints?.maxWidth == 12)
          .toList();

      expect(containers.isNotEmpty, isTrue);

      final decoration = containers.first.decoration as BoxDecoration;
      expect(decoration.color, equals(IssueStateColors.reported));
    });

    testWidgets('renders connecting line between entries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: testHistory),
          ),
        ),
      );

      // Should have at least one line connector (for non-last items)
      // The line is a Container with width: 2
      final lineContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints?.maxWidth == 2)
          .toList();

      // First entry should have a line, last entry should not
      expect(lineContainers.isNotEmpty, isTrue);
    });

    testWidgets('does not render line after last entry', (tester) async {
      final singleEntry = [
        StateHistoryEntry(
          state: IssueState.reported,
          changedAt: DateTime(2025, 1, 12),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueTimeline(history: singleEntry),
          ),
        ),
      );

      // With only one entry, there should be no connecting line
      final expandedWidgets = tester.widgetList<Expanded>(find.byType(Expanded));
      // The Expanded for the line should not exist for single entry
      expect(expandedWidgets.length, equals(1)); // Only content Expanded
    });
  });
}
