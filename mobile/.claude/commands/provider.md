# Riverpod Provider Generator

name: "provider"
description: "Generate Riverpod provider with proper patterns"
parameters:
  - name: "name"
    description: "Provider name in camelCase (e.g., 'issues', 'currentUser', 'issueDetail')"
    required: true
  - name: "feature"
    description: "Feature folder (e.g., 'issues', 'members', 'auth')"
    required: true
  - name: "type"
    description: "Provider type: simple, family, async, notifier"
    required: false
    default: "async"

---

You are an expert Flutter/Riverpod developer generating providers for the MunServ mobile app.

## Task

Generate a `{{type}}` provider named `{{name}}` in the `{{feature}}` feature.

## Provider Types

### Simple Provider
Use for: Singleton instances, computed values, dependency injection

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{{feature}}_providers.g.dart';

@riverpod
{{ReturnType}} {{name}}({{Name}}Ref ref) {
  // For dependency injection
  final dependency = ref.watch(someDependencyProvider);
  return SomeService(dependency);
}
```

### Family Provider (with parameters)
Use for: Data that varies by ID, filtered lists

```dart
@riverpod
Future<Issue?> issueDetail(IssueDetailRef ref, String id) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getById(id);
  return switch (result) {
    Success(:final data) => data,
    Failure() => null,
  };
}

// Usage
ref.watch(issueDetailProvider(issueId))
```

### Async Provider
Use for: Data fetching, async operations

```dart
@riverpod
Future<List<Issue>> issues(IssuesRef ref) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getAll();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

// In widget
final issuesAsync = ref.watch(issuesProvider);
issuesAsync.when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const LoadingSpinner(),
  error: (e, _) => ErrorDisplay(error: e),
);
```

### Notifier (with state mutations)
Use for: Complex state, CRUD operations, optimistic updates

```dart
@riverpod
class IssueListNotifier extends _$IssueListNotifier {
  @override
  Future<List<Issue>> build() async {
    final repository = ref.watch(issueRepositoryProvider);
    final result = await repository.getAll();
    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> addIssue(CreateIssueRequest request) async {
    final repository = ref.read(issueRepositoryProvider);
    final result = await repository.create(request);

    switch (result) {
      case Success(:final data):
        // Optimistic update
        state = state.whenData((issues) => [...issues, data]);
      case Failure(:final error):
        // Handle error - could show snackbar via another provider
        throw error;
    }
  }

  Future<void> removeIssue(String id) async {
    // Optimistic remove
    final previous = state.value;
    state = state.whenData(
      (issues) => issues.where((i) => i.id != id).toList(),
    );

    final repository = ref.read(issueRepositoryProvider);
    final result = await repository.delete(id);

    if (result case Failure()) {
      // Rollback on failure
      if (previous != null) {
        state = AsyncData(previous);
      }
    }
  }
}
```

### Stream Provider
Use for: Real-time data, WebSocket connections

```dart
@riverpod
Stream<List<Issue>> issuesStream(IssuesStreamRef ref) {
  final repository = ref.watch(issueRepositoryProvider);
  return repository.watchAll();
}
```

## File Location

```
lib/features/{{feature}}/providers/{{feature}}_providers.dart
```

Or for feature-specific providers:
```
lib/features/{{feature}}/providers/{{name}}_provider.dart
```

## Provider Patterns

### Repository Provider
```dart
@riverpod
IssueRepository issueRepository(IssueRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return IssueRepositoryImpl(IssueApi(dio));
}
```

### Filtered/Derived Provider
```dart
@riverpod
Future<List<Issue>> issuesByState(IssuesByStateRef ref, IssueState state) async {
  final issues = await ref.watch(issuesProvider.future);
  return issues.where((i) => i.state == state).toList();
}
```

### Combined Provider
```dart
@riverpod
Future<IssueWithMember> issueWithReporter(
  IssueWithReporterRef ref,
  String issueId,
) async {
  final issue = await ref.watch(issueDetailProvider(issueId).future);
  if (issue == null) throw NotFoundException('Issue not found');

  final member = await ref.watch(memberDetailProvider(issue.reporterId).future);
  return IssueWithMember(issue: issue, reporter: member);
}
```

## ref.watch vs ref.read

```dart
// ✅ ref.watch - For reactive dependencies (rebuilds on change)
@override
Widget build(BuildContext context, WidgetRef ref) {
  final issues = ref.watch(issuesProvider);
  // ...
}

// ✅ ref.read - For one-time reads (callbacks, mutations)
onPressed: () {
  ref.read(issueNotifierProvider.notifier).addIssue(request);
}

// ✅ ref.invalidate - Force refresh
onRefresh: () => ref.invalidate(issuesProvider),

// ❌ Never watch in callbacks
onPressed: () {
  final issues = ref.watch(issuesProvider); // WRONG!
}
```

## Error Handling Pattern

```dart
@riverpod
class IssueNotifier extends _$IssueNotifier {
  @override
  Future<Issue?> build(String id) async {
    return _fetchIssue(id);
  }

  Future<Issue?> _fetchIssue(String id) async {
    final repository = ref.read(issueRepositoryProvider);
    final result = await repository.getById(id);
    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<bool> updateState(IssueState newState) async {
    final previousState = state;

    // Optimistic update
    state = state.whenData((issue) => issue?.copyWith(state: newState));

    final repository = ref.read(issueRepositoryProvider);
    final result = await repository.updateState(id, newState);

    return switch (result) {
      Success(:final data):
        state = AsyncData(data);
        true;
      Failure(:final error):
        // Rollback
        state = previousState;
        false;
    };
  }
}
```

## Best Practices

### Do
- [ ] Use `@riverpod` annotation for code generation
- [ ] Return `AsyncValue` for async operations
- [ ] Use pattern matching for Result handling
- [ ] Implement optimistic updates for better UX
- [ ] Use `ref.invalidate()` for cache refresh
- [ ] Keep providers focused and single-purpose

### Don't
- [ ] Don't use `ref.watch` in callbacks
- [ ] Don't mutate state directly (use notifier)
- [ ] Don't catch errors in providers (let them propagate)
- [ ] Don't create providers inside widgets
- [ ] Don't use `StateProvider` for complex state

## Output

1. Create provider file at correct location
2. Include proper imports and part directive
3. Generate appropriate provider type
4. Run `flutter pub run build_runner build`
5. Verify with `flutter analyze`
