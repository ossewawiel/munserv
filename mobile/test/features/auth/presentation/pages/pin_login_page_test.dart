import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
// ignore: implementation_imports
import 'package:riverpod/src/framework.dart' show Override;
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/presentation/pages/pin_login_page.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/pin_input_field.dart';
import 'package:munserv_mobile/features/auth/providers/auth_providers.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shared/services/biometric_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthApi extends Mock implements AuthApi {}

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockAuthApi mockAuthApi;
  late MockBiometricService mockBiometricService;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockAuthApi = MockAuthApi();
    mockBiometricService = MockBiometricService();
  });

  Widget createTestWidget({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageProvider.overrideWithValue(mockStorage),
        authApiProvider.overrideWithValue(mockAuthApi),
        biometricServiceProvider.overrideWithValue(mockBiometricService),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const PinLoginPage(),
      ),
    );
  }

  group('PinLoginPage', () {
    testWidgets('renders PIN input field', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PinInputField), findsOneWidget);
    });

    testWidgets('renders page title', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('shows user email in subtitle', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'user@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Enter your PIN to continue as user@example.com'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Use Different Account" button', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Use Different Account'), findsOneWidget);
    });

    testWidgets('shows biometric button when biometrics enabled', (
      tester,
    ) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => true);
      when(() => mockStorage.getBiometricPin()).thenAnswer((_) async => '1234');
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => true);
      // Mock biometric auth to fail silently (cancelled)
      when(
        () => mockBiometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => BiometricResult.failed());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Use Fingerprint / Face ID'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });

    testWidgets('hides biometric button when biometrics not enabled', (
      tester,
    ) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Use Fingerprint / Face ID'), findsNothing);
      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });

    testWidgets('renders info box with PIN instructions', (tester) async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Enter your 4-digit PIN to quickly access your account.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
