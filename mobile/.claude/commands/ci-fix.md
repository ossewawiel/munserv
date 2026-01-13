# CI/CD Failure Debugger

name: "ci-fix"
description: "Debug CI/CD failures for mobile (analyze, test, build)"
parameters:
  - name: "error_type"
    description: "Failure type: analyze, test, build, all"
    required: true
  - name: "error_log"
    description: "Paste error output or path to log file"
    required: false

---

You are an expert Flutter developer debugging CI/CD failures for the MunServ mobile app.

## Task

Debug and fix `{{error_type}}` failure(s) in the mobile CI/CD pipeline.

## CI Commands Reference

```bash
flutter analyze              # Static analysis
flutter test                 # Unit + widget tests
flutter build apk --debug    # Android debug build
flutter build apk --release  # Android release build
flutter build ios --debug    # iOS debug build
flutter build ios --release  # iOS release build
dart format --set-exit-if-changed . # Format check
```

## Debugging by Error Type

### Analyze Failures (Static Analysis)

**Run locally:**
```bash
flutter analyze
# or auto-fix some issues
dart fix --apply
```

**Common Analyzer Errors:**

#### Undefined Name
```
error: Undefined name 'SomeClass'
```
**Fix:** Add missing import or check spelling
```dart
// Add import
import 'package:munserv/features/issues/domain/some_class.dart';
```

#### Type Mismatch
```
error: A value of type 'X' can't be assigned to a variable of type 'Y'
```
**Fix:** Correct the type or add conversion
```dart
// Before
final Issue issue = issueDto; // IssueDto

// After
final Issue issue = issueDto.toDomain();
```

#### Missing Return Type
```
warning: The function 'methodName' should have a return type
```
**Fix:** Add explicit return type
```dart
// Before
getIssue(String id) async { ... }

// After
Future<Issue?> getIssue(String id) async { ... }
```

#### Unused Import/Variable
```
warning: Unused import 'dart:async'
warning: The value of the local variable 'x' isn't used
```
**Fix:** Remove unused code or prefix with underscore
```dart
// Remove unused import
// Or use underscore for intentionally unused
final _ = someValue;
```

#### Missing const
```
info: Prefer const with constant constructors
```
**Fix:** Add const keyword
```dart
// Before
SizedBox(height: 16)

// After
const SizedBox(height: 16)
```

### Test Failures

**Run locally:**
```bash
flutter test
# or specific test
flutter test test/features/issues/providers/issue_providers_test.dart
# with verbose output
flutter test --reporter expanded
```

**Common Test Failures:**

#### Assertion Failed
```
Expected: <X>
  Actual: <Y>
```
**Fix:** Check test expectations or implementation
```dart
// Debug: Print actual value
print('Actual value: $result');

// Verify test setup
// Verify mock configuration
```

#### Mock Not Called
```
No matching calls
```
**Fix:** Check mock setup
```dart
// Ensure mock is configured
when(() => mockRepository.getAll()).thenAnswer((_) async => []);

// Verify method is actually called in code under test
verify(() => mockRepository.getAll()).called(1);
```

#### Widget Test Pump Issues
```
The following assertion was thrown running a test:
A Timer is still pending even after the widget tree was disposed
```
**Fix:** Use pumpAndSettle or proper async handling
```dart
// Before
await tester.pump();

// After - wait for all animations/timers
await tester.pumpAndSettle();

// Or with timeout
await tester.pumpAndSettle(const Duration(seconds: 5));
```

#### Provider Not Found
```
ProviderScope was not found
```
**Fix:** Wrap widget with ProviderScope
```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(mockRepository),
    ],
    child: MaterialApp(
      home: const MyWidget(),
    ),
  ),
);
```

### Build Failures

**Run locally:**
```bash
flutter build apk --debug
flutter build apk --debug --verbose # More output
flutter clean && flutter pub get && flutter build apk # Clean build
```

**Common Build Errors:**

#### Dependency Resolution
```
Because X depends on Y ^1.0.0 which doesn't match any versions
```
**Fix:** Update dependency constraints
```yaml
# pubspec.yaml
dependencies:
  package_name: ^1.2.3  # Check pub.dev for compatible version
```

#### Missing Code Generation
```
Could not find the correct Provider
Part directive missing
```
**Fix:** Run build_runner
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Android Build Issues
```
Execution failed for task ':app:processDebugResources'
```
**Fix:** Check Android configuration
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### iOS Build Issues
```
Signing for "Runner" requires a development team
```
**Fix:** Configure signing in Xcode or use development profile
```bash
# In ios/Runner.xcodeproj/project.pbxproj
# Set DEVELOPMENT_TEAM = ""

# Or open in Xcode
cd ios && open Runner.xcworkspace
# Select Runner > Signing & Capabilities > Team
```

#### Minimum SDK Version
```
uses-sdk:minSdkVersion 16 cannot be smaller than version 21
```
**Fix:** Update android/app/build.gradle
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // or higher as needed
    }
}
```

### Format Failures

**Run locally:**
```bash
dart format .
# Check only (CI mode)
dart format --set-exit-if-changed .
```

**Fix:** Run formatter
```bash
dart format lib test
```

## Quick Fix Workflow

1. **Identify error type** from CI log
2. **Run locally** to reproduce
3. **Apply fix** based on patterns above
4. **Verify fix** by re-running command
5. **Commit and push**

## Full CI Check Before Commit

```bash
# Run all checks
flutter analyze && flutter test && flutter build apk --debug
```

## Common Fix Commands

```bash
# Auto-fix analyzer issues
dart fix --apply

# Regenerate code
flutter pub run build_runner build --delete-conflicting-outputs

# Clean everything
flutter clean
rm -rf pubspec.lock
flutter pub get

# Refresh dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Format code
dart format lib test integration_test
```

## Environment Issues

### Flutter Version Mismatch
```bash
# Check version
flutter --version

# Switch to specific version (if using FVM)
fvm use 3.19.0

# Or update
flutter upgrade
```

### Package Cache Issues
```bash
# Clear pub cache
flutter pub cache repair

# Or clean and reinstall
flutter clean
rm -rf .dart_tool
rm pubspec.lock
flutter pub get
```

## Output

1. **Parse** error log to identify failure type
2. **Reproduce** locally with appropriate command
3. **Diagnose** root cause using patterns above
4. **Fix** the issue
5. **Verify** fix passes locally
6. **Report** what was fixed
