---
name: mobile-patterns
description: Full Flutter + Riverpod 3 + Freezed 4 patterns for the MunServ mobile app - Freezed models, enums with transitions, the Result type, repositories, Riverpod providers and notifiers, page and widget structure, null safety, async handling, import order, and flutter_test/Mocktail test patterns. Load when writing or reviewing mobile code beyond what mobile/CLAUDE.md covers.
---

# Mobile patterns

The core rules live in `mobile/CLAUDE.md`. This skill is the worked-example catalogue.
Riverpod 3 note: generated providers take `Ref ref` (not `IssuesRef`); Riverpod annotation and generator are on major version 4.

## Freezed Model Pattern

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

@freezed
class Issue with _$Issue {
  const Issue._();  // Private constructor for methods
  
  const factory Issue({
    required String id,
    required String sectorId,
    required IssueType type,
    required IssueState state,
    required GeoPoint location,
    required int heat,
    required DateTime reportedAt,
  }) = _Issue;

  // Domain logic lives here
  bool canTransitionTo(IssueState newState) =>
      state.allowedTransitions.contains(newState);

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
}
```

## Enum Pattern

```dart
enum IssueState {
  reported,
  confirmed,
  inProgress,
  fixed,
  rejected,
  reopened;

  Set<IssueState> get allowedTransitions => switch (this) {
    reported => {confirmed, rejected},
    confirmed => {inProgress, rejected},
    inProgress => {fixed, rejected},
    fixed => {reopened},
    rejected => {},
    reopened => {confirmed},
  };

  String get displayName => switch (this) {
    reported => 'Reported',
    confirmed => 'Confirmed',
    inProgress => 'In Progress',
    fixed => 'Fixed',
    rejected => 'Rejected',
    reopened => 'Reopened',
  };
}
```

## Result Type Pattern

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppError error) = Failure<T>;
}

// Usage
Result<Issue> result = await repository.getIssue(id);
switch (result) {
  case Success(:final data):
    // use data
  case Failure(:final error):
    // handle error
}
```

## Repository Pattern

```dart
abstract class IssueRepository {
  Future<Result<List<Issue>>> getIssues();
  Future<Result<Issue>> getIssue(String id);
  Future<Result<Issue>> reportIssue(ReportIssueRequest request);
}

class IssueRepositoryImpl implements IssueRepository {
  final IssueApi _api;
  
  IssueRepositoryImpl(this._api);

  @override
  Future<Result<List<Issue>>> getIssues() async {
    try {
      final response = await _api.getIssues();
      final issues = response.map((dto) => dto.toDomain()).toList();
      return Result.success(issues);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(e.toString()));
    }
  }
}
```

## Riverpod Provider Patterns

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'issue_providers.g.dart';

// Repository provider
@riverpod
IssueRepository issueRepository(IssueRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return IssueRepositoryImpl(IssueApi(dio));
}

// Async data provider
@riverpod
Future<List<Issue>> issues(IssuesRef ref) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getIssues();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

// Filtered provider
@riverpod
Future<List<Issue>> issuesByState(IssuesByStateRef ref, IssueState state) async {
  final issues = await ref.watch(issuesProvider.future);
  return issues.where((i) => i.state == state).toList();
}

// Notifier for mutations
@riverpod
class IssueNotifier extends _$IssueNotifier {
  @override
  Future<Issue?> build(String id) async {
    final repository = ref.watch(issueRepositoryProvider);
    final result = await repository.getIssue(id);
    return switch (result) {
      Success(:final data) => data,
      Failure() => null,
    };
  }

  Future<void> updateState(IssueState newState) async {
    final repository = ref.read(issueRepositoryProvider);
    state = const AsyncLoading();
    final result = await repository.updateState(id, newState);
    state = switch (result) {
      Success(:final data) => AsyncData(data),
      Failure(:final error) => AsyncError(error, StackTrace.current),
    };
  }
}
```

## Widget Patterns

### Page (Data Fetching)
```dart
class IssueListPage extends ConsumerWidget {
  const IssueListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(issuesProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Issues')),
      body: issuesAsync.when(
        data: (issues) => IssueList(issues: issues),
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(issuesProvider),
        ),
      ),
    );
  }
}
```

### Widget (Presentation Only)
```dart
class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onTap;
  
  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: IssueTypeIcon(type: issue.type),
        title: Text(issue.type.displayName),
        subtitle: Text(issue.state.displayName),
        trailing: HeatBadge(heat: issue.heat),
        onTap: onTap,
      ),
    );
  }
}
```

### Extracted Sub-Widget
```dart
// Keep in same file if single-use, prefix with underscore
class _IssueCardHeader extends StatelessWidget {
  final Issue issue;
  
  const _IssueCardHeader({required this.issue});
  
  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

## Null Safety

```dart
// ✅ Required named parameters
void submitIssue({required String title, required GeoPoint location}) {}

// ✅ Null-aware operators
final name = user?.name ?? 'Unknown';
final issues = response.data?.issues ?? [];

// ✅ Early return
if (user == null) return;

// ✅ Pattern matching
if (result case Success(:final data)) {
  // use data
}

// ❌ Avoid late unless necessary
late final String name;  // Only for controllers, animations

// ❌ Don't force unwrap without check
final name = user!.name;  // Only after confirmed non-null
```

## Async Patterns

```dart
// ✅ AsyncValue with Riverpod
issuesAsync.when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(error: e),
);

// ✅ Try/catch at repository level
Future<Result<Issue>> fetchIssue(String id) async {
  try {
    final response = await api.get('/issues/$id');
    return Result.success(Issue.fromJson(response.data));
  } catch (e) {
    return Result.failure(AppError.from(e));
  }
}

// ❌ Don't use FutureBuilder (use Riverpod)
// ❌ Don't catch errors in widgets (handle in providers)
```

## Import Order

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';

// 4. Project imports (package for cross-feature, relative within feature)
import 'package:munserv/shared/widgets/loading_spinner.dart';
import '../domain/issue.dart';

// 5. Part files
part 'issue.freezed.dart';
part 'issue.g.dart';
```

## Testing (flutter_test + Mocktail)

### Test Framework Stack
- **flutter_test** - Core testing framework
- **Mocktail** - Mocking library for Dart
- **Riverpod** - ProviderContainer for provider tests

### Unit Test Pattern (Providers)
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

  test('returns issues on success', () async {
    // Arrange
    when(() => mockRepository.getAll())
        .thenAnswer((_) async => Result.success([testIssue]));

    // Act
    final result = await container.read(issuesProvider.future);

    // Assert
    expect(result, hasLength(1));
    verify(() => mockRepository.getAll()).called(1);
  });
}
```

### Widget Test Pattern
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  testWidgets('shows issue list when data loads', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          issueRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(home: IssueListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IssueCard), findsWidgets);
  });
}
```

### Test Commands
```bash
flutter test                       # Run all tests
flutter test test/unit/            # Run specific directory
flutter test --coverage            # Generate coverage report
flutter test --reporter expanded   # Verbose output
```

### Mocktail Patterns
```dart
// Setup mock
when(() => mock.method(any())).thenAnswer((_) async => result);
when(() => mock.method(any())).thenThrow(Exception());

// Verify calls
verify(() => mock.method(any())).called(1);
verifyNever(() => mock.otherMethod());

// Capture arguments
final captured = verify(() => mock.method(captureAny())).captured;
```
