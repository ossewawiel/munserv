import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_card.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_type_icon.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';

void main() {
  final testIssue = IssueSummary(
    id: 'test-1',
    type: IssueType.pothole,
    state: IssueState.reported,
    location: const GeoPoint(latitude: -26.1234, longitude: 28.0567),
    heat: 75,
    thumbnailUrl: 'https://example.com/thumb.jpg',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  group('IssueCard', () {
    testWidgets('displays issue information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IssueCard(issue: testIssue)),
        ),
      );

      expect(find.text('Pothole'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('displays IssueTypeIcon instead of thumbnail', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IssueCard(issue: testIssue)),
        ),
      );

      expect(find.byType(IssueTypeIcon), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueCard(issue: testIssue, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(IssueCard));
      expect(tapped, isTrue);
    });

    testWidgets('displays location coordinates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IssueCard(issue: testIssue)),
        ),
      );

      expect(find.textContaining('-26.1234'), findsOneWidget);
      expect(find.textContaining('28.0567'), findsOneWidget);
    });

    testWidgets('displays relative time for recent issues', (tester) async {
      final recentIssue = IssueSummary(
        id: 'test-2',
        type: IssueType.waterLeak,
        state: IssueState.confirmed,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
        heat: 50,
        thumbnailUrl: 'https://example.com/thumb.jpg',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IssueCard(issue: recentIssue)),
        ),
      );

      expect(find.text('30m ago'), findsOneWidget);
    });
  });
}
