# Code Review for Flutter/Dart Patterns

name: "review-code"
description: "Review code for adherence to Flutter/Dart patterns"
parameters:
  - name: "target"
    description: "File or directory to review (e.g., 'issues/', 'issues/providers/issue_providers.dart')"
    required: true
  - name: "focus"
    description: "Focus area: all, dart, flutter, riclaudeverpod, architecture"
    required: false
    default: "all"

---

You are an expert Flutter developer reviewing code for the MunServ mobile app.

## Task

Review `{{target}}` for adherence to project patterns and best practices.

## Review Criteria by Severity

### CRITICAL (Must Fix Before Merge)

#### Dart
- [ ] Using **var** instead of **final** for immutable variables
- [ ] Using **dynamic** type explicitly
- [ ] Force unwrapping with **!** without null check
- [ ] Using mutable collections without need
- [ ] Throwing exceptions for business logic flow

#### Flutter
- [ ] Using **setState** for complex state (should use Riverpod)
- [ ] Business logic in widgets
- [ ] Missing **const** constructors where possible
- [ ] Hardcoded colors (should use **Theme.of(context).colorScheme**)
- [ ] Using **.withOpacity()** on theme colors

#### Riverpod
- [ ] Using **ref.watch** in callbacks (should use **ref.read**)
- [ ] Not disposing resources in notifiers
- [ ] Mocking providers incorrectly in tests
- [ ] Missing **@riverpod** annotation

#### Architecture
- [ ] Domain classes with Flutter dependencies
- [ ] Providers directly calling APIs (should use Repository)
- [ ] Widgets calling repositories directly
- [ ] Circular dependencies between features

#### Security
- [ ] Hardcoded API keys or secrets
- [ ] Logging sensitive data
- [ ] Missing input validation

### HIGH (Should Fix)

#### Dart
- [ ] Missing type annotations on public APIs
- [ ] Long functions (>30 lines)
- [ ] Deep nesting (>3 levels)
- [ ] Not using pattern matching for sealed classes
- [ ] Using **if-else** chains instead of **switch**

#### Flutter
- [ ] Missing **Key** on widgets in lists
- [ ] Not using **ListView.builder** for long lists
- [ ] Creating objects inside **build()** method
- [ ] Not extracting widgets (>50 lines)

#### Riverpod
- [ ] Not handling all **AsyncValue** states (data, loading, error)
- [ ] Using **ref.watch** for one-time reads
- [ ] Not using family providers for parameterized data
- [ ] Missing error handling in notifiers

#### Testing
- [ ] Missing tests for providers
- [ ] Tests not following AAA pattern
- [ ] Mocking domain classes (should test directly)
- [ ] No widget tests for pages

#### Architecture
- [ ] Repository returning domain errors as exceptions
- [ ] Service layer missing Result type
- [ ] Feature depending on another feature's internals

### MEDIUM (Consider Fixing)

#### Dart
- [ ] Not using named parameters for functions with >2 params
- [ ] Not using data classes (Freezed) for DTOs
- [ ] Missing documentation on public API
- [ ] Using string concatenation instead of interpolation

#### Flutter
- [ ] Verbose widget code that could be simplified
- [ ] Not using semantic widgets (**SizedBox** vs **Container**)
- [ ] Inconsistent padding/margin values

#### Architecture
- [ ] Large files (>300 lines)
- [ ] God class (too many responsibilities)
- [ ] Missing interface for repository

### LOW (Nice to Have)

- [ ] Inconsistent naming conventions
- [ ] Import order not following convention
- [ ] Missing blank lines between methods
- [ ] Verbose code that could be simplified

## Best Practices Checklist

### Dart Patterns

```dart
// ✅ GOOD - final and immutability
final issue = await repository.getIssue(id);
final updated = issue.copyWith(state: newState);

// ❌ BAD - var and mutation
var issue = await repository.getIssue(id);
issue.state = newState; // Won't work with Freezed anyway
```

```dart
// ✅ GOOD - Safe null handling
final name = user?.name ?? 'Unknown';
if (user case final u?) {
  sendNotification(u);
}

// ❌ BAD - Force unwrap
final name = user!.name;
```

```dart
// ✅ GOOD - Result pattern
Future<Result<Issue>> getIssue(String id) async {
  try {
    final response = await api.get('/issues/$id');
    return Result.success(Issue.fromJson(response.data));
  } catch (e) {
    return Result.failure(AppError.from(e));
  }
}

// ❌ BAD - Throwing exceptions
Future<Issue> getIssue(String id) async {
  final response = await api.get('/issues/$id');
  if (response.statusCode != 200) {
    throw Exception('Failed to load issue');
  }
  return Issue.fromJson(response.data);
}
```

### Flutter Patterns

```dart
// ✅ GOOD - ConsumerWidget with Riverpod
class IssueListPage extends ConsumerWidget {
  const IssueListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(issuesProvider);
    return issues.when(
      data: (data) => IssueList(issues: data),
      loading: () => const LoadingSpinner(),
      error: (e, _) => ErrorDisplay(error: e),
    );
  }
}

// ❌ BAD - StatefulWidget with setState
class IssueListPage extends StatefulWidget {
  @override
  State<IssueListPage> createState() => _IssueListPageState();
}

class _IssueListPageState extends State<IssueListPage> {
  List<Issue>? issues;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    final data = await repository.getAll();
    setState(() {
      issues = data;
      loading = false;
    });
  }
}
```

```dart
// ✅ GOOD - Theme colors
final colors = Theme.of(context).colorScheme;
Container(color: colors.primaryContainer)

// ❌ BAD - Hardcoded colors
Container(color: Color(0xFF233D36))
Container(color: colors.primary.withOpacity(0.5))
```

### Riverpod Patterns

```dart
// ✅ GOOD - ref.watch for reactive, ref.read for callbacks
@override
Widget build(BuildContext context, WidgetRef ref) {
  final issues = ref.watch(issuesProvider); // Reactive

  return ElevatedButton(
    onPressed: () {
      ref.read(issueNotifierProvider.notifier).refresh(); // One-time
    },
    child: const Text('Refresh'),
  );
}

// ❌ BAD - ref.watch in callback
onPressed: () {
  final issues = ref.watch(issuesProvider); // WRONG!
}
```

```dart
// ✅ GOOD - Handle all AsyncValue states
issuesAsync.when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const LoadingSpinner(),
  error: (error, _) => ErrorDisplay(error: error),
);

// ❌ BAD - Using else
issuesAsync.when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const LoadingSpinner(),
  error: (_, __) => const SizedBox(), // Lost error info!
);
```

### Architecture Patterns

```dart
// ✅ GOOD - Domain entity (pure Dart)
@freezed
class Issue with _$Issue {
  const Issue._();

  const factory Issue({
    required String id,
    required IssueState state,
  }) = _Issue;

  bool canTransitionTo(IssueState newState) =>
      state.allowedTransitions.contains(newState);
}

// ❌ BAD - Domain with Flutter dependency
import 'package:flutter/material.dart'; // NO!

class Issue {
  final Color stateColor; // NO! Should be in presentation layer
}
```

## Output Format

For each issue found, report in this format:

```markdown
## Code Review Report for {{target}}

### Summary
- CRITICAL: X issues
- HIGH: X issues
- MEDIUM: X issues
- LOW: X issues

### CRITICAL Issues

1. **[dart/force-unwrap]** Line 42: Using **!** without null check
   - File: lib/features/issues/providers/issue_providers.dart:42
   - Current: final issue = snapshot.data!
   - Fix: Use null check or pattern matching

### HIGH Issues

1. **[flutter/missing-const]** Line 55: Missing const constructor
   - File: lib/features/issues/presentation/issue_card.dart:55
   - Current: SizedBox(height: 16)
   - Fix: Add **const** keyword

### Recommendations

1. Consider extracting **_buildIssueList** to separate widget
2. Add tests for **IssueNotifier.updateState** method
```

## Workflow

### Step 1: Run Static Analysis Tools

Run these commands first and include results in the report:

```bash
# Static analysis - catches type errors, unused variables, deprecated APIs
flutter analyze lib/{{target}}

# Format check - ensures code follows Dart style guidelines
dart format --set-exit-if-changed --output=none lib/{{target}}

# Suggested fixes - shows available automatic fixes
dart fix --dry-run lib/{{target}}
```

If **{{target}}** is a directory, analyze the full directory. If it's a specific file, analyze just that file.

### Step 2: Manual Code Review

1. Read all files in **{{target}}**
2. Check against all criteria for **{{focus}}** area
3. Report issues by severity
4. Provide specific fix recommendations

## Output Format (Updated)

```markdown
## Code Review Report for {{target}}

### Static Analysis Results

#### `flutter analyze`
[Output from flutter analyze - or "No issues found"]

#### `dart format`
[Output from format check - or "All files properly formatted"]

#### `dart fix --dry-run`
[Suggested fixes available - or "No fixes available"]

### Manual Review Summary
- CRITICAL: X issues
- HIGH: X issues
- MEDIUM: X issues
- LOW: X issues

### CRITICAL Issues
...
```

## Output

Run the static analysis tools first, then perform manual review
