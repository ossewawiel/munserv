import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
// ignore: implementation_imports
import 'package:riverpod/src/framework.dart' show Override;
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/auth_state.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';
import 'package:munserv_mobile/features/auth/presentation/pages/change_password_page.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/loading_button.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/password_input_field.dart';
import 'package:munserv_mobile/features/auth/providers/auth_providers.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthApi extends Mock implements AuthApi {}

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockAuthApi mockAuthApi;

  const testTokens = AuthTokens(
    accessToken: 'access_abc',
    refreshToken: 'refresh_xyz',
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockAuthApi = MockAuthApi();
  });

  Widget createTestWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageProvider.overrideWithValue(mockStorage),
        authApiProvider.overrideWithValue(mockAuthApi),
        // Start in mustChangePassword state
        authProvider.overrideWith(
          () => TestAuthNotifier(
            initialState: const AuthState.mustChangePassword(
              tokens: testTokens,
              memberId: 'member_123',
            ),
          ),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const ChangePasswordPage(),
      ),
    );
  }

  group('ChangePasswordPage', () {
    testWidgets('renders three password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have 3 password input fields
      expect(find.byType(PasswordInputField), findsNWidgets(3));
    });

    testWidgets('renders correct labels for password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });

    testWidgets('renders submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LoadingButton), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
    });

    testWidgets('renders password requirements hint', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'At least 8 characters, with uppercase, lowercase, and numbers',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders helper text for current password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Enter the temporary password from your welcome email'),
        findsOneWidget,
      );
    });

    testWidgets('validates password too short', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter current password
      await tester.enterText(find.byType(TextFormField).at(0), 'temppass123');

      // Enter new password (too short)
      await tester.enterText(find.byType(TextFormField).at(1), 'Short1');

      // Enter confirm password
      await tester.enterText(find.byType(TextFormField).at(2), 'Short1');

      // Submit
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('validates password needs uppercase', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter current password
      await tester.enterText(find.byType(TextFormField).at(0), 'temppass123');

      // Enter new password (no uppercase)
      await tester.enterText(find.byType(TextFormField).at(1), 'lowercase123');

      // Enter confirm password
      await tester.enterText(find.byType(TextFormField).at(2), 'lowercase123');

      // Submit
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must contain at least one uppercase letter'),
        findsOneWidget,
      );
    });

    testWidgets('validates password needs lowercase', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter current password
      await tester.enterText(find.byType(TextFormField).at(0), 'temppass123');

      // Enter new password (no lowercase)
      await tester.enterText(find.byType(TextFormField).at(1), 'UPPERCASE123');

      // Enter confirm password
      await tester.enterText(find.byType(TextFormField).at(2), 'UPPERCASE123');

      // Submit
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must contain at least one lowercase letter'),
        findsOneWidget,
      );
    });

    testWidgets('validates password needs number', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter current password
      await tester.enterText(find.byType(TextFormField).at(0), 'temppass123');

      // Enter new password (no number)
      await tester.enterText(find.byType(TextFormField).at(1), 'NoNumberPass');

      // Enter confirm password
      await tester.enterText(find.byType(TextFormField).at(2), 'NoNumberPass');

      // Submit
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must contain at least one number'),
        findsOneWidget,
      );
    });

    testWidgets('validates passwords must match', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter current password
      await tester.enterText(find.byType(TextFormField).at(0), 'temppass123');

      // Enter new password (valid)
      await tester.enterText(find.byType(TextFormField).at(1), 'ValidPass123');

      // Enter different confirm password
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'DifferentPass123',
      );

      // Submit
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('renders page header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Change Your Password'), findsOneWidget);
      expect(
        find.text('Please set a new secure password to continue'),
        findsOneWidget,
      );
    });
  });
}

/// Test notifier that allows setting initial state for ChangePasswordPage
class TestAuthNotifier extends AuthNotifier {
  final AuthState initialState;

  TestAuthNotifier({required this.initialState});

  @override
  AuthState build() {
    return initialState;
  }
}
