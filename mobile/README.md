# MunServ Mobile

Flutter mobile app for community members to report and track municipal issues.

## Setup

### Prerequisites

- Flutter 3.x
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

### Installation

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Running the App

```bash
# Connect to backend (default)
flutter run

# Connect to mock API (for testing)
flutter run --dart-define=API_PORT=3001

# Real device on same network
flutter run --dart-define=API_HOST=192.168.1.100
```

### Android emulator (Linux)

```bash
# The Android SDK comes from mise (see ../mise.local.toml); create an AVD once, then:
flutter emulators --launch <avd-name>
flutter run                    # 10.0.2.2:8080 reaches the backend on the host
```
`scripts/start-dev.sh` is the legacy WSL2-to-Windows emulator bridge and is not needed on Linux.

## Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on connected device |
| `flutter test` | Run all tests |
| `flutter analyze` | Lint check |
| `dart run build_runner build` | Generate Freezed/Riverpod code |
| `dart format .` | Format code |

## Widgetbook

A catalogue of every shared widget and `IssueCard` variant, rendered with the
real `AppTheme` in light and dark mode. Registry: `design/registry/mobile.md`.

```bash
flutter run -t widgetbook/main.dart          # Run the catalogue
flutter build web -t widgetbook/main.dart    # Build for the web (output gitignored)
```

A new shared widget is not done until it has a use-case in `widgetbook/use_cases/`
and a row in `design/registry/mobile.md`.

## Tech Stack

- **Flutter 3.x** with Dart
- **Riverpod** for state management
- **Freezed** for immutable models
- **GoRouter** for navigation
- **Dio** for HTTP client
- **flutter_map** for maps

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── features/
│   ├── auth/          # Authentication
│   ├── issues/        # Issue reporting & viewing
│   ├── home/          # Home dashboard
│   └── profile/       # User profile
├── shared/
│   ├── models/        # Shared domain models
│   ├── widgets/       # Reusable widgets
│   ├── theme/         # Colors, typography, spacing
│   ├── providers/     # Global providers
│   └── utils/         # Utilities
└── routing/
    └── app_router.dart
```

## Development with Claude Code

### Available Skills

| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | Full TDD workflow: Specify → Test → Code → Refactor → Quality |
| `/screen` | Generate screen with GoRouter navigation |
| `/widget` | Generate Flutter widget (StatelessWidget/ConsumerWidget) |
| `/shared-widget` | Generate shared widget for design system |
| `/provider` | Create Riverpod provider (async/notifier/family) |
| `/repository` | Create repository with Result pattern |
| `/model` | Generate Freezed model with JSON serialization |
| `/test` | Generate unit test (Mocktail) |
| `/widget-test` | Generate widget test |
| `/integration-test` | Generate integration test |
| `/review-code` | Code review for Flutter/Dart patterns |
| `/ci-fix` | Debug CI/CD failures |

### TDD Workflow

```
1. SPECIFY    → Define acceptance criteria
2. TEST       → Write failing tests FIRST (Red)
3. CODE       → Implement to pass tests (Green)
4. REFACTOR   → Clean up, fix review issues
5. QUALITY    → Run analyze, tests, format
```

Use `/dev-cycle "your task"` to orchestrate this workflow.

## Architecture

```
Presentation (UI) → Providers (State) → Repository (Data) → API (Network)
```

| Layer | Responsibility |
|-------|----------------|
| Presentation | Widgets, pages, user interaction |
| Providers | State management, business logic (Riverpod) |
| Repository | Data operations, caching, Result pattern |
| API | HTTP calls, serialization (Dio) |

## Key Patterns

### Result Type
```dart
Result<Issue> result = await repository.getIssue(id);
switch (result) {
  case Success(:final data): // use data
  case Failure(:final error): // handle error
}
```

### Freezed Models
```dart
@freezed
class Issue with _$Issue {
  const factory Issue({
    required String id,
    required IssueType type,
    required IssueState state,
  }) = _Issue;

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
}
```

### Riverpod Providers
```dart
@riverpod
Future<List<Issue>> issues(IssuesRef ref) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getIssues();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}
```

## Styling

Use constants from `shared/theme/typography.dart`:

```dart
// Spacing
SizedBox(height: Spacing.md)    // 16

// Border radius
BorderRadius.circular(Radii.md) // 8

// Icon sizes
Icon(icon, size: IconSizes.xl)  // 48

// Colors from theme
final colors = Theme.of(context).colorScheme;
colors.primary
colors.surface
colors.onSurface
```

## Testing

```bash
flutter test                          # All tests
flutter test test/unit/               # Specific directory
flutter test --coverage               # With coverage
flutter test --reporter expanded      # Verbose output
```

### Test Pattern
```dart
void main() {
  group('IssueRepository', () {
    late MockIssueApi mockApi;
    late IssueRepository repository;

    setUp(() {
      mockApi = MockIssueApi();
      repository = IssueRepository(mockApi);
    });

    test('returns issues on success', () async {
      when(() => mockApi.getIssues()).thenAnswer(
        (_) async => [testIssue],
      );

      final result = await repository.getIssues();

      expect(result, isA<Success<List<Issue>>>());
    });
  });
}
```

## Documentation

- [CLAUDE.md](CLAUDE.md) — Architecture patterns, styling rules, coding conventions
- [Mobile Theming Guide](../specs/Mobile_Theming_Guide.md) — M3 theming, colors
- [Testing Strategy](../specs/archive/Testing_Strategy.md) — Test patterns
