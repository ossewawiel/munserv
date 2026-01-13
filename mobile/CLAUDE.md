# Mobile Context - Flutter + Riverpod + Freezed

## Related Specs
- **DevOps Strategy** (`/specs/DevOps_Strategy.md`): Git workflow, commit format, CI/CD
- **Testing Strategy** (`/specs/Testing_Strategy.md`): Test patterns, widget tests

## Layer Architecture

```
Presentation (UI) → Providers (State) → Repository (Data) → API (Network)
```

| Layer | Responsibility | Contains |
|-------|----------------|----------|
| Presentation | Widgets, pages, user interaction | Pages, Widgets |
| Providers | State management, business logic | Riverpod providers |
| Repository | Data operations, caching | Repository classes |
| API | HTTP calls, serialization | API clients, DTOs |

## Folder Structure

```
lib/
├── main.dart
├── app.dart
├── features/
│   ├── issues/
│   │   ├── data/
│   │   │   ├── issue_api.dart
│   │   │   ├── issue_repository.dart
│   │   │   └── dtos/
│   │   │       └── issue_dto.dart
│   │   ├── domain/
│   │   │   ├── issue.dart            ← Freezed model
│   │   │   ├── issue_state.dart      ← Enum
│   │   │   └── issue_type.dart       ← Enum
│   │   ├── providers/
│   │   │   └── issue_providers.dart  ← Riverpod providers
│   │   └── presentation/
│   │       ├── issue_list_page.dart
│   │       ├── issue_detail_page.dart
│   │       └── widgets/
│   │           ├── issue_card.dart
│   │           └── issue_status_badge.dart
│   ├── members/
│   │   └── [same structure]
│   └── auth/
│       └── [same structure]
├── shared/
│   ├── widgets/
│   │   ├── loading_spinner.dart
│   │   └── error_display.dart
│   ├── providers/
│   │   └── dio_provider.dart
│   ├── utils/
│   │   └── result.dart
│   └── theme/
│       └── app_theme.dart
└── routing/
    └── app_router.dart
```

## Material Design 3 Theming

The app uses Material Design 3 with a generated tonal palette system.

**Full spec:** [`/specs/Mobile_Theming_Guide.md`](/specs/Mobile_Theming_Guide.md)

### Brand Colors

| Role | Color | Hex |
|------|-------|-----|
| Primary | Forest Green | `#233D36` |
| Secondary | Terracotta | `#D9613F` |
| Tertiary | Warm Beige | `#F3EDDA` |

### Using Theme Colors

```dart
// ✅ DO: Use ColorScheme from theme
final colors = Theme.of(context).colorScheme;

colors.primary              // Primary actions
colors.primaryContainer     // FAB, prominent containers
colors.secondary            // Secondary actions
colors.secondaryContainer   // Selected nav items
colors.surfaceContainerLow  // Cards, dialogs
colors.surfaceContainerHigh // Menus, elevated surfaces
colors.onSurface            // Primary text
colors.onSurfaceVariant     // Secondary text

// ❌ DON'T: Hardcode colors
Container(color: Color(0xFF233D36))

// ❌ DON'T: Use .withOpacity() on theme colors
colors.primary.withOpacity(0.5) // Use semantic variant instead
```

### M3 Component Specifications

| Component | Height | Radius | Notes |
|-----------|--------|--------|-------|
| Buttons | 40dp | Stadium | 48dp touch target |
| Cards | - | 12dp | 1dp elevation |
| Nav Bar | 80dp | - | Pill indicator |
| FAB | 56dp | 16dp | primaryContainer |
| Chips | 32dp | 8dp | - |
| Inputs | - | 4dp | Filled style |
| Dialogs | - | 28dp | surfaceContainerHigh |

### Theme Files

| File | Purpose |
|------|---------|
| `shared/theme/colors.dart` | M3ColorSchemes, brand colors |
| `shared/theme/app_theme.dart` | ThemeData builder |
| `shared/theme/typography.dart` | TextTheme, Spacing, Radii |
| `shared/providers/theme_provider.dart` | Light/dark mode state |

### Semantic Colors

```dart
// Issue states
IssueStateColors.reported   // Orange
IssueStateColors.confirmed  // Blue
IssueStateColors.inProgress // Purple
IssueStateColors.fixed      // Green
IssueStateColors.rejected   // Gray

// Heat priority
HeatColors.fromHeat(75)     // Returns red for high heat
```

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

## Forbidden
- `setState` for complex state (use Riverpod)
- `dynamic` type (use proper typing)
- Business logic in widgets
- Deeply nested widgets (>4 levels) without extraction
- `late` except for controllers/animations
- FutureBuilder/StreamBuilder (use Riverpod)
- Mutable state in widgets

## Build Commands (WSL2)
```bash
flutter pub get                    # Install dependencies
dart run build_runner build        # Generate freezed/riverpod code
flutter analyze                    # Lint check
flutter test                       # Run tests
flutter run                        # Run on connected device/emulator
```

## Parameterized Builds (API Host & Port)

The app uses `--dart-define` to configure the API for different environments:

```bash
# For Backend (default after migration) - port 8080
flutter build apk --debug
flutter run

# For Mock API (testing/development) - port 3001
flutter run --dart-define=API_PORT=3001

# For Real Device on same network
flutter build apk --debug --dart-define=API_HOST=192.168.1.100
flutter run --dart-define=API_HOST=192.168.1.100

# Full customization (host + port)
flutter run --dart-define=API_HOST=192.168.1.100 --dart-define=API_PORT=8080

# For Release build
flutter build apk --release --dart-define=API_HOST=your.api.host
```

**Default Values:**
- `API_HOST`: `10.0.2.2` (Android emulator's localhost)
- `API_PORT`: `8080` (Spring Boot backend)

### Real Device Testing Setup

1. **On Windows (mock API host):**
   ```powershell
   # Open firewall for mock API
   netsh advfirewall firewall add rule name="Mock API 3001" dir=in action=allow protocol=TCP localport=3001

   # Find your IP
   ipconfig  # Look for IPv4 Address (e.g., 192.168.1.100)

   # Start mock API
   cd D:\sourcecode\pocs\munserv\infrastructure\mock-api
   npm start
   ```

2. **Enable USB Debugging on phone:**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"
   - Connect via USB, accept debugging prompt

3. **Build and install:**
   ```bash
   flutter build apk --debug --dart-define=API_HOST=YOUR_WINDOWS_IP
   flutter install
   # Or manually copy build/app/outputs/flutter-apk/app-debug.apk to phone
   ```

## WSL2 + Windows Emulator Setup

Running Flutter in WSL2 with an Android emulator on Windows requires special configuration.

### One-Time Windows Setup (Run PowerShell as Administrator)
```powershell
# Add port proxy to forward ADB connections from WSL2 to Windows localhost
netsh interface portproxy add v4tov4 listenport=5555 listenaddress=0.0.0.0 connectport=5555 connectaddress=127.0.0.1

# Allow through Windows Firewall
netsh advfirewall firewall add rule name="ADB 5555" dir=in action=allow protocol=TCP localport=5555
```

### Daily Development Workflow
```bash
# 1. Start emulator on Windows (Android Studio or command line)

# 2. Connect from WSL2 (use the provided script)
./scripts/start-dev.sh

# Or manually:
adb-win   # if you added the function to ~/.bashrc

# 3. Run the app
flutter run
```

### Quick Start Script
Use the provided script: `./scripts/start-dev.sh`

This script:
1. Checks if Windows emulator is running
2. Enables TCP/IP mode on the emulator
3. Connects WSL2 ADB to Windows emulator
4. Verifies Flutter can see the device

### Troubleshooting

**"Connection refused" error:**
- Ensure emulator is running on Windows
- Verify port proxy is set up: `netsh interface portproxy show v4tov4`
- Check Windows Firewall allows port 5555

**Flutter doesn't see device:**
- Run `adb devices` to verify connection
- Try `adb kill-server && adb start-server`
- Re-run `./scripts/start-dev.sh`

**Wrong IP address:**
The correct Windows IP is the default gateway, not the DNS server:
```bash
# Correct (default gateway)
ip route show | grep default | awk '{print $3}'

# Wrong (DNS server)
cat /etc/resolv.conf | grep nameserver
```

### Alternative: Run Emulator in WSL2 (Slower)
If you prefer running the emulator directly in WSL2 (with nested virtualization):
```bash
# Enable KVM (requires .wslconfig with nestedVirtualization=true)
sudo modprobe kvm && sudo modprobe kvm-intel

# Add user to kvm group
sudo usermod -aG kvm $USER
sudo chown root:kvm /dev/kvm
sudo chmod 660 /dev/kvm

# Run emulator
$ANDROID_HOME/emulator/emulator -avd Pixel_6_API_34 -gpu swiftshader_indirect -no-audio &
```
Note: This uses nested virtualization and will be slower than the Windows emulator.

## Code Generation
After adding/modifying Freezed models or Riverpod providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
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

## Available Skills

Skills are located in `.claude/commands/`. Use `/skill-name` to invoke.

### Code Generation
| Skill | Purpose |
|-------|---------|
| `/widget` | Generate Flutter widget (StatelessWidget/ConsumerWidget) |
| `/feature` | Scaffold complete feature module |
| `/provider` | Create Riverpod provider (async/notifier/family) |
| `/repository` | Create repository with Result pattern |
| `/model` | Generate Freezed model with JSON serialization |
| `/screen` | Generate screen with GoRouter navigation |

### Quality & Testing
| Skill | Purpose |
|-------|---------|
| `/test` | Generate unit test (Mocktail) |
| `/widget-test` | Generate widget test |
| `/integration-test` | Generate integration test |
| `/review` | Code review for Flutter/Dart patterns |
| `/ci-fix` | Debug CI/CD failures (analyze, test, build) |

### Workflow
| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | Full TDD workflow: Specify → Test → Code → Refactor → Quality Gate |

## TDD Development Cycle

When adding functionality, follow this workflow:

```
1. SPECIFY    → Define acceptance criteria
2. TEST       → Write failing tests FIRST (Red)
3. CODE       → Implement to pass tests (Green)
4. REFACTOR   → Clean up, fix review issues
5. QUALITY    → Run analyze, tests, format
6. WIDGET     → Add widget tests for new UI
7. PRE-COMMIT → Full build verification
```

Use `/dev-cycle "your task description"` to orchestrate this workflow.
