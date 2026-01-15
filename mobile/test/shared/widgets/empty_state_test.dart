import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.check_circle,
              title: 'Test Title',
              subtitle: 'Test subtitle message',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test subtitle message'), findsOneWidget);
    });

    testWidgets('displays action widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.check_circle,
              title: 'Test Title',
              action: FilledButton(
                onPressed: () {},
                child: const Text('Action Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Action Button'), findsOneWidget);
    });

    testWidgets('does not display subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.check_circle, title: 'Test Title'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      // Should only find title, no subtitle
      expect(find.byType(Text), findsNWidgets(1));
    });

    testWidgets('does not display action when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.check_circle, title: 'Test Title'),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('EmptyState.noIssues', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noIssues())),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('No Issues'), findsOneWidget);
      expect(find.textContaining('No issues have been reported'), findsOneWidget);
    });

    testWidgets('displays refresh button when onRefresh provided', (
      tester,
    ) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noIssues(onRefresh: () => refreshed = true),
          ),
        ),
      );

      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(refreshed, isTrue);
    });

    testWidgets('does not display button when onRefresh is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noIssues())),
      );

      expect(find.text('Refresh'), findsNothing);
    });
  });

  group('EmptyState.noReports', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noReports())),
      );

      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.text('No Reports Yet'), findsOneWidget);
      expect(find.textContaining('haven\'t reported'), findsOneWidget);
    });

    testWidgets('displays action button when onReport provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmptyState.noReports(onReport: () {})),
        ),
      );

      expect(find.text('Report Issue'), findsOneWidget);
    });
  });

  group('EmptyState.networkError', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.networkError())),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.textContaining('internet connection'), findsOneWidget);
    });

    testWidgets('displays retry button when onRetry provided', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.networkError(onRetry: () => retried = true),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('EmptyState.noResults', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noResults())),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No Results'), findsOneWidget);
      expect(find.textContaining('No issues match'), findsOneWidget);
    });

    testWidgets('displays query in message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmptyState.noResults(query: 'pothole')),
        ),
      );

      expect(find.textContaining('"pothole"'), findsOneWidget);
    });

    testWidgets('displays clear button when onClear provided', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noResults(onClear: () => cleared = true),
          ),
        ),
      );

      expect(find.text('Clear Filters'), findsOneWidget);

      await tester.tap(find.text('Clear Filters'));
      expect(cleared, isTrue);
    });
  });

  group('EmptyState.locationError', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.locationError())),
      );

      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.text('Location Unavailable'), findsOneWidget);
      expect(find.textContaining('location services'), findsOneWidget);
    });

    testWidgets('displays enable button when onRetry provided', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.locationError(onRetry: () => retried = true),
          ),
        ),
      );

      expect(find.text('Enable Location'), findsOneWidget);

      await tester.tap(find.text('Enable Location'));
      expect(retried, isTrue);
    });
  });
}
