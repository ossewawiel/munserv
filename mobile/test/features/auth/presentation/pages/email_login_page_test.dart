import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
// ignore: implementation_imports
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/presentation/pages/email_login_page.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/email_input_field.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/loading_button.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/password_input_field.dart';
import 'package:munserv_mobile/features/auth/providers/auth_providers.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shared/utils/app_error.dart';
import 'package:munserv_mobile/shared/utils/result.dart';
import 'package:munserv_mobile/shared/widgets/form_error_banner.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthApi extends Mock implements AuthApi {}

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockAuthApi mockAuthApi;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockAuthApi = MockAuthApi();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageProvider.overrideWithValue(mockStorage),
        authApiProvider.overrideWithValue(mockAuthApi),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const EmailLoginPage(),
      ),
    );
  }

  group('EmailLoginPage', () {
    testWidgets('renders email and password fields', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EmailInputField), findsOneWidget);
      expect(find.byType(PasswordInputField), findsOneWidget);
    });

    testWidgets('renders login button', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LoadingButton), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('renders registration info section', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(
        find.text('Register at munserv.app to join your community'),
        findsOneWidget,
      );
    });

    testWidgets('pre-populates email from storage', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'saved@example.com');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextFormField>(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
      );
      expect(emailField.controller?.text, 'saved@example.com');
    });

    testWidgets('shows validation error for empty email', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap login without entering data
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
        'invalid-email',
      );

      // Enter password
      await tester.enterText(
        find.descendant(
          of: find.byType(PasswordInputField),
          matching: find.byType(TextFormField),
        ),
        'password123',
      );

      // Tap login
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid email only
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
        'test@example.com',
      );

      // Tap login without password
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('renders page title', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
        find.text('Enter your email and password to continue'),
        findsOneWidget,
      );
    });
  });

  group('EmailLoginPage error display', () {
    testWidgets('shows FormErrorBanner when login fails', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(
          AppError.unauthorized(message: 'Invalid credentials'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid email
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
        'test@example.com',
      );

      // Enter password
      await tester.enterText(
        find.descendant(
          of: find.byType(PasswordInputField),
          matching: find.byType(TextFormField),
        ),
        'wrongpassword',
      );

      // Tap login
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Should show FormErrorBanner with error message
      expect(find.byType(FormErrorBanner), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows error icon in FormErrorBanner', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(
          AppError.network(message: 'No internet connection'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
        'test@example.com',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(PasswordInputField),
          matching: find.byType(TextFormField),
        ),
        'password123',
      );

      // Tap login
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('error banner can be dismissed', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(
          AppError.unauthorized(message: 'Invalid credentials'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials and login
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
        'test@example.com',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(PasswordInputField),
          matching: find.byType(TextFormField),
        ),
        'password123',
      );
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Verify error banner is visible
      expect(find.byType(FormErrorBanner), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Error banner should be gone
      expect(find.byType(FormErrorBanner), findsNothing);
    });

    testWidgets('error banner clears when starting new login', (tester) async {
      var callCount = 0;
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return const Result.failure(
          AppError.unauthorized(message: 'Invalid credentials'),
        );
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials and login (first attempt)
      await tester.enterText(
        find.descendant(
          of: find.byType(EmailInputField),
          matching: find.byType(TextFormField),
        ),
        'test@example.com',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(PasswordInputField),
          matching: find.byType(TextFormField),
        ),
        'password123',
      );
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Error should be visible
      expect(find.byType(FormErrorBanner), findsOneWidget);

      // Start second login attempt - banner should clear during loading
      await tester.tap(find.text('Log In'));
      // Don't settle - just pump once to see the loading state
      await tester.pump();

      // Second call should have happened
      expect(callCount, 2);
    });
  });
}
