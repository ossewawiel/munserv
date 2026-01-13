# Unit Test Generator

name: "test"
description: "Generate unit test with Mocktail for Flutter"
parameters:
  - name: "target"
    description: "File path to test (e.g., 'lib/features/issues/providers/issue_providers.dart')"
    required: true
  - name: "type"
    description: "Test type: provider, repository, model, util"
    required: false
    default: "provider"

---

You are an expert Flutter developer generating unit tests for the MunServ mobile app.

## Task

Generate unit tests for `{{target}}` of type `{{type}}`.

## Test Framework Stack

- **flutter_test** - Core testing framework
- **Mocktail** - Mocking library (not Mockito)
- **Riverpod** - ProviderContainer for provider tests

## File Location

```
test/{{path_from_lib}}_test.dart
```

Example: `lib/features/issues/providers/issue_providers.dart` →
`test/features/issues/providers/issue_providers_test.dart`

## Provider Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv/features/issues/providers/issue_providers.dart';
import 'package:munserv/features/issues/data/issue_repository.dart';
import 'package:munserv/features/issues/domain/issue.dart';
import 'package:munserv/shared/utils/result.dart';

// Mock classes
class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late MockIssueRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockIssueRepository();
    container = ProviderContainer(
      overrides: [
        issueRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('issuesProvider', () {
    test('returns list of issues on success', () async {
      // Arrange
      final testIssues = [
        Issue(
          id: '1',
          sectorId: 'sector-1',
          type: IssueType.pothole,
          state: IssueState.reported,
          location: const GeoPoint(latitude: -26.0, longitude: 28.0),
          heat: 50,
          reportedAt: DateTime.now(),
        ),
      ];
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => Result.success(testIssues));

      // Act
      final result = await container.read(issuesProvider.future);

      // Assert
      expect(result, equals(testIssues));
      verify(() => mockRepository.getAll()).called(1);
    });

    test('throws error on failure', () async {
      // Arrange
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => const Result.failure(
                AppError.network('Connection failed'),
              ));

      // Act & Assert
      expect(
        () => container.read(issuesProvider.future),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('issueDetailProvider', () {
    test('returns issue when found', () async {
      // Arrange
      final testIssue = Issue(
        id: 'issue-1',
        sectorId: 'sector-1',
        type: IssueType.pothole,
        state: IssueState.reported,
        location: const GeoPoint(latitude: -26.0, longitude: 28.0),
        heat: 50,
        reportedAt: DateTime.now(),
      );
      when(() => mockRepository.getById('issue-1'))
          .thenAnswer((_) async => Result.success(testIssue));

      // Act
      final result = await container.read(issueDetailProvider('issue-1').future);

      // Assert
      expect(result, equals(testIssue));
    });

    test('returns null when not found', () async {
      // Arrange
      when(() => mockRepository.getById('not-found'))
          .thenAnswer((_) async => const Result.failure(
                AppError.notFound('Issue not found'),
              ));

      // Act
      final result = await container.read(issueDetailProvider('not-found').future);

      // Assert
      expect(result, isNull);
    });
  });
}
```

## Repository Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv/features/issues/data/issue_api.dart';
import 'package:munserv/features/issues/data/issue_repository.dart';
import 'package:munserv/features/issues/data/dtos/issue_dto.dart';
import 'package:munserv/shared/utils/result.dart';

class MockIssueApi extends Mock implements IssueApi {}

void main() {
  late MockIssueApi mockApi;
  late IssueRepositoryImpl repository;

  setUp(() {
    mockApi = MockIssueApi();
    repository = IssueRepositoryImpl(mockApi);
  });

  group('getAll', () {
    test('returns Success with mapped issues on API success', () async {
      // Arrange
      final dtos = [
        IssueDto(
          id: '1',
          sectorId: 'sector-1',
          type: 'pothole',
          state: 'reported',
          latitude: -26.0,
          longitude: 28.0,
          heat: 50,
          reportedAt: '2024-01-15T10:00:00Z',
        ),
      ];
      when(() => mockApi.getAll()).thenAnswer((_) async => dtos);

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result, isA<Success<List<Issue>>>());
      final issues = (result as Success<List<Issue>>).data;
      expect(issues.length, equals(1));
      expect(issues.first.id, equals('1'));
    });

    test('returns Failure on DioException', () async {
      // Arrange
      when(() => mockApi.getAll()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/issues'),
          type: DioExceptionType.connectionError,
        ),
      );

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result, isA<Failure<List<Issue>>>());
      final error = (result as Failure).error;
      expect(error, isA<NetworkError>());
    });

    test('returns Failure on unexpected exception', () async {
      // Arrange
      when(() => mockApi.getAll()).thenThrow(Exception('Unexpected'));

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result, isA<Failure<List<Issue>>>());
      final error = (result as Failure).error;
      expect(error, isA<UnknownError>());
    });
  });
}
```

## Model Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv/features/issues/domain/issue.dart';
import 'package:munserv/features/issues/domain/issue_state.dart';

void main() {
  group('Issue', () {
    late Issue issue;

    setUp(() {
      issue = Issue(
        id: 'issue-1',
        sectorId: 'sector-1',
        type: IssueType.pothole,
        state: IssueState.reported,
        location: const GeoPoint(latitude: -26.0, longitude: 28.0),
        heat: 50,
        reportedAt: DateTime(2024, 1, 15),
      );
    });

    test('canTransitionTo returns true for valid transitions', () {
      expect(issue.canTransitionTo(IssueState.confirmed), isTrue);
      expect(issue.canTransitionTo(IssueState.rejected), isTrue);
    });

    test('canTransitionTo returns false for invalid transitions', () {
      expect(issue.canTransitionTo(IssueState.fixed), isFalse);
      expect(issue.canTransitionTo(IssueState.inProgress), isFalse);
    });

    test('heatLabel returns correct label for heat value', () {
      expect(Issue(heat: 90).heatLabel, equals('Critical'));
      expect(Issue(heat: 70).heatLabel, equals('High'));
      expect(Issue(heat: 50).heatLabel, equals('Medium'));
      expect(Issue(heat: 20).heatLabel, equals('Low'));
    });

    test('copyWith creates new instance with updated values', () {
      final updated = issue.copyWith(state: IssueState.confirmed);

      expect(updated.state, equals(IssueState.confirmed));
      expect(updated.id, equals(issue.id)); // unchanged
    });

    test('fromJson parses JSON correctly', () {
      final json = {
        'id': 'issue-1',
        'sector_id': 'sector-1',
        'type': 'pothole',
        'state': 'reported',
        'latitude': -26.0,
        'longitude': 28.0,
        'heat': 50,
        'reported_at': '2024-01-15T10:00:00Z',
      };

      final issue = Issue.fromJson(json);

      expect(issue.id, equals('issue-1'));
      expect(issue.type, equals(IssueType.pothole));
    });
  });

  group('IssueState', () {
    test('allowedTransitions returns correct transitions', () {
      expect(
        IssueState.reported.allowedTransitions,
        containsAll([IssueState.confirmed, IssueState.rejected]),
      );
      expect(
        IssueState.fixed.allowedTransitions,
        contains(IssueState.reopened),
      );
      expect(
        IssueState.rejected.allowedTransitions,
        isEmpty,
      );
    });

    test('displayName returns human-readable name', () {
      expect(IssueState.inProgress.displayName, equals('In Progress'));
    });
  });
}
```

## Notifier Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late MockIssueRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockIssueRepository();
    container = ProviderContainer(
      overrides: [
        issueRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('IssueListNotifier', () {
    test('addIssue adds issue to list on success', () async {
      // Arrange
      final existingIssue = _createTestIssue(id: '1');
      final newIssue = _createTestIssue(id: '2');

      when(() => mockRepository.getAll())
          .thenAnswer((_) async => Result.success([existingIssue]));
      when(() => mockRepository.create(any()))
          .thenAnswer((_) async => Result.success(newIssue));

      // Load initial data
      await container.read(issueListNotifierProvider.future);

      // Act
      await container
          .read(issueListNotifierProvider.notifier)
          .addIssue(CreateIssueRequest(/* ... */));

      // Assert
      final state = container.read(issueListNotifierProvider);
      expect(state.value, hasLength(2));
      expect(state.value!.last.id, equals('2'));
    });

    test('refresh invalidates and reloads data', () async {
      // Arrange
      when(() => mockRepository.getAll())
          .thenAnswer((_) async => Result.success([_createTestIssue()]));

      // Act
      await container.read(issueListNotifierProvider.notifier).refresh();

      // Assert
      verify(() => mockRepository.getAll()).called(greaterThanOrEqualTo(1));
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

## Mocktail Patterns

```dart
// Setup mock
when(() => mock.method(any())).thenAnswer((_) async => result);
when(() => mock.method(any())).thenThrow(Exception());

// Verify calls
verify(() => mock.method(any())).called(1);
verifyNever(() => mock.otherMethod());

// Capture arguments
final captured = verify(() => mock.method(captureAny())).captured;
expect(captured.first, equals(expectedArg));

// Register fallback values (for custom types)
setUpAll(() {
  registerFallbackValue(CreateIssueRequest(/* ... */));
});
```

## Test Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/issues/providers/issue_providers_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests matching pattern
flutter test --name "IssueState"

# Run with verbose output
flutter test --reporter expanded
```

## Output

1. Create test file at correct location
2. Include proper imports and mocks
3. Use Arrange-Act-Assert pattern
4. Cover success, failure, and edge cases
5. Run `flutter test` to verify
