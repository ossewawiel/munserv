# Integration Test Generator

name: "integration-test"
description: "Generate integration test for feature flows"
parameters:
  - name: "feature"
    description: "Feature to test (e.g., 'issues', 'auth', 'members')"
    required: true
  - name: "flow"
    description: "Flow to test (e.g., 'create_issue', 'login', 'view_details')"
    required: false

---

You are an expert Flutter developer generating integration tests for the MunServ mobile app.

## Task

Generate integration tests for the `{{feature}}` feature{{#if flow}}, specifically the `{{flow}}` flow{{/if}}.

## File Location

```
integration_test/{{feature}}_test.dart
```

## Integration Test Setup

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:munserv/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('full app smoke test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app starts
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
```

## Feature Integration Test Pattern

```dart
// integration_test/issues_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:munserv/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Issues Feature', () {
    testWidgets('view issues list flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to issues (if not default screen)
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify issues are displayed
      expect(find.byType(IssueCard), findsWidgets);
    });

    testWidgets('view issue detail flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for issues to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on first issue
      await tester.tap(find.byType(IssueCard).first);
      await tester.pumpAndSettle();

      // Verify detail page shown
      expect(find.byType(IssueDetailPage), findsOneWidget);

      // Verify issue data displayed
      expect(find.text('Reported'), findsOneWidget);
    });

    testWidgets('create issue flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap FAB to create
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify create form shown
      expect(find.byType(CreateIssuePage), findsOneWidget);

      // Fill form
      await tester.enterText(
        find.byKey(const Key('issue_description')),
        'Test pothole on Main Street',
      );

      // Select issue type
      await tester.tap(find.byKey(const Key('issue_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pothole').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify success - back on list
      expect(find.byType(IssueListPage), findsOneWidget);
    });

    testWidgets('pull to refresh flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Pull to refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify refresh completed (no error)
      expect(find.byType(IssueCard), findsWidgets);
    });
  });
}
```

## Authentication Flow Test

```dart
// integration_test/auth_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:munserv/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication', () {
    testWidgets('login flow with phone number', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should start at login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Enter phone number
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '+27821234567',
      );
      await tester.pumpAndSettle();

      // Tap request OTP
      await tester.tap(find.text('Request OTP'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show OTP entry
      expect(find.byType(OtpVerificationPage), findsOneWidget);

      // Enter OTP (test environment accepts 123456)
      await tester.enterText(
        find.byKey(const Key('otp_field')),
        '123456',
      );
      await tester.pumpAndSettle();

      // Verify OTP
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on home page
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('logout flow', (tester) async {
      // Start with logged in state
      app.main(/* with test auth state */);
      await tester.pumpAndSettle();

      // Open drawer/menu
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm logout
      await tester.tap(find.text('Yes, logout'));
      await tester.pumpAndSettle();

      // Should be back at login
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('session expiry redirects to login', (tester) async {
      // Setup expired token scenario
      app.main(/* with expired token */);
      await tester.pumpAndSettle();

      // Try to fetch protected resource
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should redirect to login
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Session expired'), findsOneWidget);
    });
  });
}
```

## Screenshot Capture

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture screenshots', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Capture login screen
    await binding.takeScreenshot('01_login_screen');

    // Navigate and capture more screens
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await binding.takeScreenshot('02_home_screen');
  });
}
```

## Test with Different Configurations

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Issues - Light Theme', () {
    testWidgets('displays correctly', (tester) async {
      app.main(themeMode: ThemeMode.light);
      await tester.pumpAndSettle();
      // Tests...
    });
  });

  group('Issues - Dark Theme', () {
    testWidgets('displays correctly', (tester) async {
      app.main(themeMode: ThemeMode.dark);
      await tester.pumpAndSettle();
      // Tests...
    });
  });

  group('Issues - Tablet Layout', () {
    testWidgets('shows master-detail', (tester) async {
      // Set tablet size
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      app.main();
      await tester.pumpAndSettle();
      // Tests...
    });
  });
}
```

## Mock Backend for Integration Tests

```dart
// integration_test/helpers/mock_server.dart
import 'dart:io';
import 'dart:convert';

class MockServer {
  late HttpServer _server;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3001);
    _server.listen(_handleRequest);
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;

    if (request.uri.path == '/api/v1/issues' && request.method == 'GET') {
      response.write(jsonEncode({
        'content': [
          {
            'id': '1',
            'type': 'pothole',
            'state': 'reported',
            // ...
          }
        ]
      }));
    } else {
      response.statusCode = HttpStatus.notFound;
    }

    await response.close();
  }

  Future<void> stop() async {
    await _server.close();
  }
}

// Usage in test
void main() {
  late MockServer mockServer;

  setUpAll(() async {
    mockServer = MockServer();
    await mockServer.start();
  });

  tearDownAll(() async {
    await mockServer.stop();
  });

  testWidgets('test with mock server', (tester) async {
    app.main(apiUrl: 'http://localhost:3001');
    // ...
  });
}
```

## Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test

# Run specific test file
flutter test integration_test/issues_test.dart

# Run on specific device
flutter test integration_test --device-id <device_id>

# Run with coverage
flutter test integration_test --coverage

# Run and capture screenshots
flutter test integration_test --dart-define=SCREENSHOTS=true
```

## Best Practices

### Do
- [ ] Test complete user flows end-to-end
- [ ] Use realistic data and scenarios
- [ ] Add appropriate wait times for async operations
- [ ] Capture screenshots for visual regression
- [ ] Test both success and error paths
- [ ] Test on multiple screen sizes

### Don't
- [ ] Don't mock everything - use real API when possible
- [ ] Don't assume instant state changes
- [ ] Don't hardcode wait times unnecessarily
- [ ] Don't skip error state testing

## Output

1. Create integration test file
2. Test complete user flows
3. Include proper setup/teardown
4. Add screenshot capture for key screens
5. Run `flutter test integration_test` to verify
