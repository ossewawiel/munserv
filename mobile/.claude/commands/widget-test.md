# Widget Test Generator

name: "widget-test"
description: "Generate widget test for Flutter widgets"
parameters:
  - name: "widget"
    description: "Widget name to test (e.g., 'IssueCard', 'IssueListPage')"
    required: true
  - name: "feature"
    description: "Feature folder (e.g., 'issues', 'members')"
    required: true

---

You are an expert Flutter developer generating widget tests for the MunServ mobile app.

## Task

Generate widget tests for `{{widget}}` in the `{{feature}}` feature.

## File Location

```
test/features/{{feature}}/presentation/{{snake_case(widget)}}_test.dart
```

## Widget Test Pattern (StatelessWidget)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv/features/issues/presentation/widgets/issue_card.dart';
import 'package:munserv/features/issues/domain/issue.dart';

void main() {
  group('IssueCard', () {
    late Issue testIssue;

    setUp(() {
      testIssue = Issue(
        id: 'issue-1',
        sectorId: 'sector-1',
        type: IssueType.pothole,
        state: IssueState.reported,
        location: const GeoPoint(latitude: -26.0, longitude: 28.0),
        heat: 50,
        reportedAt: DateTime(2024, 1, 15),
      );
    });

    testWidgets('displays issue type and state', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueCard(issue: testIssue),
          ),
        ),
      );

      // Assert
      expect(find.text('Pothole'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
    });

    testWidgets('displays heat badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueCard(issue: testIssue),
          ),
        ),
      );

      expect(find.byType(HeatBadge), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      // Arrange
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueCard(
              issue: testIssue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(IssueCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('applies correct theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: IssueCard(issue: testIssue),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      // Assert card styling
    });
  });
}
```

## Widget Test Pattern (ConsumerWidget with Providers)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv/features/issues/presentation/issue_list_page.dart';
import 'package:munserv/features/issues/providers/issue_providers.dart';
import 'package:munserv/features/issues/domain/issue.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
  });

  Widget createWidgetUnderTest({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        issueRepositoryProvider.overrideWithValue(mockRepository),
        ...overrides,
      ],
      child: const MaterialApp(
        home: IssueListPage(),
      ),
    );
  }

  group('IssueListPage', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      // Arrange - Repository never completes
      when(() => mockRepository.getAll()).thenAnswer(
        (_) => Future.delayed(const Duration(hours: 1)),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows issue list when data loads', (tester) async {
      // Arrange
      final issues = [
        _createTestIssue(id: '1'),
        _createTestIssue(id: '2'),
      ];
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => Result.success(issues));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(IssueCard), findsNWidgets(2));
    });

    testWidgets('shows empty state when no issues', (tester) async {
      // Arrange
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => const Result.success([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('shows error display on failure', (tester) async {
      // Arrange
      when(() => mockRepository.getAll()).thenAnswer(
        (_) async => const Result.failure(AppError.network('Failed')),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ErrorDisplay), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('refreshes on pull down', (tester) async {
      // Arrange
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => const Result.success([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - Pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockRepository.getAll()).called(greaterThanOrEqualTo(2));
    });

    testWidgets('navigates to detail on card tap', (tester) async {
      // Arrange
      final issue = _createTestIssue(id: 'issue-1');
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => Result.success([issue]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: const IssueListPage(),
            onGenerateRoute: (settings) {
              if (settings.name == '/issues/issue-1') {
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Text('Detail Page'),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(IssueCard));
      await tester.pumpAndSettle();

      // Assert - Would need proper navigation setup
    });
  });
}

Issue _createTestIssue({String id = '1'}) => Issue(
      id: id,
      sectorId: 'sector-1',
      type: IssueType.pothole,
      state: IssueState.reported,
      location: const GeoPoint(latitude: -26.0, longitude: 28.0),
      heat: 50,
      reportedAt: DateTime.now(),
    );
```

## Form Widget Test Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('CreateIssuePage', () {
    testWidgets('validates required fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Try to submit empty form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert validation errors shown
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('submits form with valid data', (tester) async {
      when(() => mockRepository.create(any()))
          .thenAnswer((_) async => Result.success(_createTestIssue()));

      await tester.pumpWidget(createWidgetUnderTest());

      // Fill form
      await tester.enterText(
        find.byKey(const Key('title_field')),
        'Test Issue',
      );
      await tester.enterText(
        find.byKey(const Key('description_field')),
        'Test Description',
      );

      // Submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify repository called
      verify(() => mockRepository.create(any())).called(1);
    });

    testWidgets('shows loading indicator during submission', (tester) async {
      when(() => mockRepository.create(any())).thenAnswer(
        (_) => Future.delayed(const Duration(hours: 1)),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Fill and submit
      await tester.enterText(
        find.byKey(const Key('title_field')),
        'Test',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Assert loading shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar on failure', (tester) async {
      when(() => mockRepository.create(any())).thenAnswer(
        (_) async => const Result.failure(AppError.validation('Invalid data')),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.byKey(const Key('title_field')),
        'Test',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert error snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
```

## Common Test Helpers

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: widget,
        ),
      ),
    );
  }
}

// Usage
await tester.pumpApp(
  const IssueListPage(),
  overrides: [
    issueRepositoryProvider.overrideWithValue(mockRepository),
  ],
);
```

## Finder Patterns

```dart
// By type
find.byType(IssueCard)
find.byType(CircularProgressIndicator)

// By text
find.text('Submit')
find.textContaining('Error')

// By key
find.byKey(const Key('submit_button'))
find.byKey(const ValueKey('issue_1'))

// By icon
find.byIcon(Icons.add)

// By widget predicate
find.byWidgetPredicate(
  (widget) => widget is Text && widget.data!.startsWith('Issue'),
)

// Descendant
find.descendant(
  of: find.byType(Card),
  matching: find.text('Title'),
)
```

## Test Commands

```bash
# Run widget tests
flutter test

# Run with golden file updates
flutter test --update-goldens

# Run specific test
flutter test test/features/issues/presentation/issue_card_test.dart
```

## Output

1. Create test file at correct location
2. Create helper widget wrapper with ProviderScope
3. Test loading, success, error, and empty states
4. Test user interactions (tap, type, scroll)
5. Mock providers and repositories
6. Run `flutter test` to verify
