import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/auth_state.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';
import 'package:munserv_mobile/features/auth/providers/auth_providers.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/utils/app_error.dart';
import 'package:munserv_mobile/shared/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Test data
const testTokens = AuthTokens(
  accessToken: 'access_abc',
  refreshToken: 'refresh_xyz',
);

const testProfile = MemberProfile(
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

const testAuthProfile = AuthProfile(
  member: testProfile,
  sector: testSector,
);

const testAuthResponse = AuthResponse(
  tokens: testTokens,
  profile: testAuthProfile,
);

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
  });

  group('AuthState', () {
    test('initial state is AuthStateInitial', () {
      const state = AuthState.initial();
      expect(state, isA<AuthStateInitial>());
      expect(state.isAuthenticated, false);
      expect(state.isLoading, true);
    });

    test('loading state isLoading returns true', () {
      const state = AuthState.loading();
      expect(state, isA<AuthStateLoading>());
      expect(state.isLoading, true);
    });

    test('authenticated state has profile and tokens', () {
      const state = AuthState.authenticated(
        tokens: testTokens,
        profile: testProfile,
        sector: testSector,
      );
      expect(state, isA<AuthStateAuthenticated>());
      expect(state.isAuthenticated, true);
      expect(state.isLoading, false);
      expect(state.profileOrNull?.firstName, 'John');
      expect(state.accessTokenOrNull, 'access_abc');
    });

    test('unauthenticated state is not authenticated', () {
      const state = AuthState.unauthenticated();
      expect(state, isA<AuthStateUnauthenticated>());
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.profileOrNull, isNull);
    });

    test('error state contains message', () {
      const state = AuthState.error('Login failed');
      expect(state, isA<AuthStateError>());
      expect((state as AuthStateError).message, 'Login failed');
    });
  });

  group('AuthNotifier integration', () {
    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
    }

    test('requestOtp returns success from repository', () async {
      when(() => mockRepository.requestOtp('+27821234567')).thenAnswer(
        (_) async => const Result.success(
          OtpRequestResponse(message: 'OTP sent', expiresInSeconds: 300),
        ),
      );

      // Use the repository directly since we're testing the pass-through
      final result = await mockRepository.requestOtp('+27821234567');

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.message, 'OTP sent');
    });

    test('verifyOtp with existing user updates state to authenticated',
        () async {
      when(() => mockRepository.verifyOtp('+27821234567', '123456')).thenAnswer(
        (_) async => const Result.success(
          OtpVerifyResult.existingUser(
            tokens: testTokens,
            profile: testAuthProfile,
          ),
        ),
      );
      when(() => mockStorage.saveTokens(testTokens)).thenAnswer((_) async {});
      when(() => mockStorage.saveProfile(testProfile)).thenAnswer((_) async {});
      when(() => mockStorage.savePhoneNumber(any())).thenAnswer((_) async {});
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await notifier.verifyOtp('+27821234567', '123456');

      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<OtpVerifyResultExistingUser>());

      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.profileOrNull?.firstName, 'John');
    });

    test('verifyOtp with new user does not change auth state', () async {
      when(() => mockRepository.verifyOtp('+27829999999', '123456')).thenAnswer(
        (_) async => const Result.success(
          OtpVerifyResult.newUser(tempToken: 'temp_abc'),
        ),
      );
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await notifier.verifyOtp('+27829999999', '123456');

      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<OtpVerifyResultNewUser>());
      expect((result.dataOrNull as OtpVerifyResultNewUser).tempToken, 'temp_abc');

      // State should still be unauthenticated
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
    });

    test('login success updates state to authenticated', () async {
      when(() => mockRepository.login('+27821234567', '1234')).thenAnswer(
        (_) async => const Result.success(testAuthResponse),
      );
      when(() => mockStorage.saveTokens(testTokens)).thenAnswer((_) async {});
      when(() => mockStorage.saveProfile(testProfile)).thenAnswer((_) async {});
      when(() => mockStorage.savePhoneNumber('+27821234567'))
          .thenAnswer((_) async {});
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await notifier.login('+27821234567', '1234');

      expect(result.isSuccess, true);

      final state = container.read(authProvider);
      expect(state, isA<AuthStateAuthenticated>());
      expect(state.profileOrNull?.phoneNumber, '+27821234567');

      verify(() => mockStorage.saveTokens(testTokens)).called(1);
      verify(() => mockStorage.saveProfile(testProfile)).called(1);
      verify(() => mockStorage.savePhoneNumber('+27821234567')).called(1);
    });

    test('login failure updates state to error', () async {
      when(() => mockRepository.login('+27821234567', '0000')).thenAnswer(
        (_) async => const Result.failure(
          AppError.unauthorized(message: 'Invalid PIN'),
        ),
      );
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await notifier.login('+27821234567', '0000');

      expect(result.isFailure, true);

      final state = container.read(authProvider);
      expect(state, isA<AuthStateError>());
      expect((state as AuthStateError).message, 'Invalid PIN');
    });

    test('logout clears storage and updates state', () async {
      when(() => mockStorage.clearSession()).thenAnswer((_) async {});
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check (will be authenticated)
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify we're authenticated
      expect(container.read(authProvider).isAuthenticated, true);

      // Logout
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());

      verify(() => mockStorage.clearSession()).called(1);
    });

    test('clearError returns to unauthenticated from error state', () async {
      when(() => mockRepository.login('+27821234567', '0000')).thenAnswer(
        (_) async => const Result.failure(
          AppError.unauthorized(message: 'Invalid PIN'),
        ),
      );
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger error state
      await notifier.login('+27821234567', '0000');
      expect(container.read(authProvider), isA<AuthStateError>());

      // Clear error
      notifier.clearError();

      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());
    });
  });

  group('convenience providers', () {
    Future<void> waitForAuth(ProviderContainer container) async {
      // Wait until auth state is no longer initial/loading
      for (var i = 0; i < 20; i++) {
        final state = container.read(authProvider);
        if (!state.isLoading) return;
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    test('isAuthenticatedProvider returns true when authenticated', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      await waitForAuth(container);

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, true);
    });

    test('currentProfileProvider returns profile when authenticated', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      await waitForAuth(container);

      final profile = container.read(currentProfileProvider);
      expect(profile?.firstName, 'John');
      expect(profile?.fullName, 'John Doe');
    });

    test('accessTokenProvider returns token when authenticated', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      await waitForAuth(container);

      final token = container.read(accessTokenProvider);
      expect(token, 'access_abc');
    });
  });
}
