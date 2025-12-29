import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_state_badge.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';

void main() {
  group('IssueStateBadge', () {
    testWidgets('displays state name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueStateBadge(state: IssueState.reported),
          ),
        ),
      );

      expect(find.text('Reported'), findsOneWidget);
    });

    testWidgets('displays correct label for each state', (tester) async {
      for (final state in IssueState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IssueStateBadge(state: state),
            ),
          ),
        );

        expect(find.text(state.displayName), findsOneWidget);
      }
    });

    testWidgets('renders in compact mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueStateBadge(
              state: IssueState.confirmed,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('Confirmed'), findsOneWidget);
      // Badge should still render text
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container, isNotNull);
    });
  });
}
