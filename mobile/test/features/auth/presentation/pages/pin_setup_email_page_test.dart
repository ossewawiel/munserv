import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
// ignore: implementation_imports
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/auth_state.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';
import 'package:munserv_mobile/features/auth/domain/member_profile_response.dart';
import 'package:munserv_mobile/features/auth/presentation/pages/pin_setup_email_page.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/pin_input_field.dart';
import 'package:munserv_mobile/features/auth/providers/auth_providers.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/services/biometric_service.dart';
import 'package:munserv_mobile/shared/utils/result.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthApi extends Mock implements AuthApi {}

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockAuthApi mockAuthApi;
  late MockBiometricService mockBiometricService;

  const testTokens = AuthTokens(
    accessToken: 'access_abc',
    refreshToken: 'refresh_xyz',
  );

  const testMemberProfileResponse = MemberProfileResponse(
    id: 'user_123',
    firstName: 'John',
    surname: 'Doe',
    phoneNumber: '+27821234567',
    address: '42 Doreen Road, Northcliff',
    registrationLocation: GeoPoint(latitude: -26.135, longitude: 27.98),
    sectorId: 'sector_1',
    status: 'active',
    createdAt: '2024-01-01T00:00:00Z',
  );

  const testSector = SectorInfo(
    id: 'sector_1',
    name: 'Northcliff',
    center: GeoPoint(latitude: -26.135, longitude: 27.98),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockAuthApi = MockAuthApi();
    mockBiometricService = MockBiometricService();
  });

  setUpAll(() {
    registerFallbackValue(
      const MemberProfile(
        id: '',
        firstName: '',
        surname: '',
        phoneNumber: '',
        address: '',
        registrationLocation: GeoPoint(latitude: 0, longitude: 0),
        sectorId: '',
        status: '',
        createdAt: '',
      ),
    );
  });

  Widget createTestWidget({AuthState? initialState}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageProvider.overrideWithValue(mockStorage),
        authApiProvider.overrideWithValue(mockAuthApi),
        biometricServiceProvider.overrideWithValue(mockBiometricService),
        // Start in pendingPinSetup state
        authProvider.overrideWith(
          () => TestPinSetupAuthNotifier(
            initialState:
                initialState ??
                const AuthState.pendingPinSetup(
                  tokens: testTokens,
                  memberId: 'member_123',
                ),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const PinSetupEmailPage(),
      ),
    );
  }

  group('PinSetupEmailPage', () {
    testWidgets('renders PIN input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PinInputField), findsOneWidget);
    });

    testWidgets('renders setup PIN title initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Set Up Your PIN'), findsOneWidget);
      expect(
        find.text('Create a 4-digit PIN for quick access'),
        findsOneWidget,
      );
    });

    testWidgets('renders PIN requirements hint', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your PIN should be 4 digits and easy to remember but hard to guess.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('changes to confirm mode after first PIN entry', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the hidden TextField used for input
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter PIN
      await tester.enterText(textField, '1234');
      await tester.pumpAndSettle();

      // Should now show confirm mode
      expect(find.text('Confirm Your PIN'), findsOneWidget);
      expect(find.text('Enter your PIN again to confirm'), findsOneWidget);
    });

    testWidgets('shows Start Over button in confirm mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter first PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      expect(find.text('Start Over'), findsOneWidget);
    });

    testWidgets('shows error when PINs do not match', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter first PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      // Enter different PIN for confirmation
      await tester.enterText(find.byType(TextField), '5678');
      await tester.pumpAndSettle();

      // Should show error - actual text from l10n is 'PINs do not match'
      expect(find.text('PINs do not match'), findsOneWidget);
    });

    testWidgets('Start Over resets to initial state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter first PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      // Verify we're in confirm mode
      expect(find.text('Confirm Your PIN'), findsOneWidget);

      // Tap Start Over
      await tester.tap(find.text('Start Over'));
      await tester.pumpAndSettle();

      // Should be back to setup mode
      expect(find.text('Set Up Your PIN'), findsOneWidget);
    });

    testWidgets('saves PIN when PINs match without biometric', (tester) async {
      when(() => mockStorage.savePin('1234')).thenAnswer((_) async {});
      when(() => mockRepository.getMe()).thenAnswer(
        (_) async => const Result.success(testMemberProfileResponse),
      );
      when(() => mockStorage.saveProfile(any())).thenAnswer((_) async {});
      when(
        () => mockAuthApi.getSector('sector_1'),
      ).thenAnswer((_) async => testSector);
      when(
        () => mockBiometricService.isBiometricAvailable(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter first PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      // Enter matching PIN for confirmation
      await tester.enterText(find.byType(TextField), '1234');

      // Use pump multiple times to handle async operations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify PIN was saved
      verify(() => mockStorage.savePin('1234')).called(1);
    });

    testWidgets('does not show back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should not have back button (can't go back from PIN setup)
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });
}

/// Test notifier for PinSetupEmailPage that allows setting initial state
class TestPinSetupAuthNotifier extends AuthNotifier {
  final AuthState initialState;

  TestPinSetupAuthNotifier({required this.initialState});

  @override
  AuthState build() {
    return initialState;
  }

  @override
  Future<void> completePinSetup(String pin) async {
    final currentState = state;
    if (currentState is! AuthStatePendingPinSetup) {
      return;
    }

    final storage = ref.read(secureStorageProvider);
    await storage.savePin(pin);

    // Fetch profile
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.getMe();

    result.when(
      success: (response) async {
        final profile = response.toMemberProfile();
        await storage.saveProfile(profile);

        final api = ref.read(authApiProvider);
        try {
          final sector = await api.getSector(response.sectorId);
          state = AuthState.authenticated(
            tokens: currentState.tokens,
            profile: profile,
            sector: sector,
          );
        } catch (e) {
          state = AuthState.authenticated(
            tokens: currentState.tokens,
            profile: profile,
            sector: SectorInfo(
              id: response.sectorId,
              name: 'Unknown',
              center: const GeoPoint(latitude: 0, longitude: 0),
            ),
          );
        }
      },
      failure: (error) {
        state = AuthState.error(error.displayMessage);
      },
    );
  }
}
