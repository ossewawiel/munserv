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

    testWidgets('uses custom icon color when provided', (tester) async {
      const customColor = Colors.purple;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.check_circle,
              title: 'Test Title',
              iconColor: customColor,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(customColor.withValues(alpha: 0.7)));
    });
  });

  group('EmptyState.noIssues', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noIssues())),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('No issues found'), findsOneWidget);
      expect(find.textContaining('no issues matching'), findsOneWidget);
    });

    testWidgets('displays action button when onReport provided', (
      tester,
    ) async {
      bool reported = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState.noIssues(onReport: () => reported = true),
          ),
        ),
      );

      expect(find.text('Report Issue'), findsOneWidget);

      await tester.tap(find.text('Report Issue'));
      expect(reported, isTrue);
    });

    testWidgets('does not display button when onReport is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noIssues())),
      );

      expect(find.text('Report Issue'), findsNothing);
    });
  });

  group('EmptyState.noReports', () {
    testWidgets('displays correct icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: EmptyState.noReports())),
      );

      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.text('No reports yet'), findsOneWidget);
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

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Connection lost'), findsOneWidget);
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

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      expect(retried, isTrue);
    });
  });
}
