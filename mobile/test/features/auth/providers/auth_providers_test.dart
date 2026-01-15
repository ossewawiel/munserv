import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/auth_state.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';
import 'package:munserv_mobile/features/auth/domain/member_login_response.dart';
import 'package:munserv_mobile/features/auth/domain/member_profile_response.dart';
import 'package:munserv_mobile/features/auth/providers/auth_providers.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/utils/app_error.dart';
import 'package:munserv_mobile/shared/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthApi extends Mock implements AuthApi {}

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

const testAuthProfile = AuthProfile(member: testProfile, sector: testSector);

const testAuthResponse = AuthResponse(
  tokens: testTokens,
  profile: testAuthProfile,
);

/// MemberProfileResponse for getMe() API validation
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

/// Test data for email-based authentication (web registration flow)
const testMemberLoginResponse = MemberLoginResponse(
  memberId: 'member_456',
  accessToken: 'email_access_token',
  refreshToken: 'email_refresh_token',
  expiresIn: 900,
  mustChangePassword: false,
);

const testMemberLoginResponseMustChange = MemberLoginResponse(
  memberId: 'member_456',
  accessToken: 'email_access_token',
  refreshToken: 'email_refresh_token',
  expiresIn: 900,
  mustChangePassword: true,
);

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockAuthApi mockAuthApi;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(testTokens);
    registerFallbackValue(testProfile);
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockAuthApi = MockAuthApi();
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
          authApiProvider.overrideWithValue(mockAuthApi),
        ],
      );
    }

    test('logout clears storage and updates state', () async {
      when(() => mockStorage.clearSession()).thenAnswer((_) async {});
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);
      when(
        () => mockAuthApi.getMe(),
      ).thenAnswer((_) async => testMemberProfileResponse);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check (will be authenticated after getMe validation)
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify we're authenticated
      expect(container.read(authProvider).isAuthenticated, true);

      // Logout
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());

      verify(() => mockStorage.clearSession()).called(1);
    });

    test('clearError does nothing when not in error state', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      // Wait for initial check
      await Future.delayed(const Duration(milliseconds: 50));

      // Should be unauthenticated
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());

      // Clear error (should do nothing since not in error state)
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
      when(
        () => mockAuthApi.getMe(),
      ).thenAnswer((_) async => testMemberProfileResponse);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
          authApiProvider.overrideWithValue(mockAuthApi),
        ],
      );

      await waitForAuth(container);

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, true);
    });

    test('currentProfileProvider returns profile when authenticated', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);
      when(
        () => mockAuthApi.getMe(),
      ).thenAnswer((_) async => testMemberProfileResponse);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
          authApiProvider.overrideWithValue(mockAuthApi),
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
      when(
        () => mockAuthApi.getMe(),
      ).thenAnswer((_) async => testMemberProfileResponse);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
          authApiProvider.overrideWithValue(mockAuthApi),
        ],
      );

      await waitForAuth(container);

      final token = container.read(accessTokenProvider);
      expect(token, 'access_abc');
    });

    test('clears session when token validation fails', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => testTokens);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => testProfile);
      when(() => mockStorage.clearSession()).thenAnswer((_) async {});
      when(() => mockAuthApi.getMe()).thenThrow(Exception('Token invalid'));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
          authApiProvider.overrideWithValue(mockAuthApi),
        ],
      );

      await waitForAuth(container);

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, false);
      verify(() => mockStorage.clearSession()).called(1);
    });
  });

  group('Email Authentication (Web Registration Flow)', () {
    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
          authApiProvider.overrideWithValue(mockAuthApi),
        ],
      );
    }

    Future<void> waitForAuth(ProviderContainer container) async {
      for (var i = 0; i < 20; i++) {
        final state = container.read(authProvider);
        if (!state.isLoading) return;
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    test(
      'loginWithEmail sets mustChangePassword state when required',
      () async {
        when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
        when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginWithEmail(
            email: 'test@example.com',
            password: 'temppass123',
          ),
        ).thenAnswer(
          (_) async => const Result.success(testMemberLoginResponseMustChange),
        );
        when(
          () => mockStorage.saveEmail('test@example.com'),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.savePassword('temppass123'),
        ).thenAnswer((_) async {});
        when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});

        final container = createContainer();
        final notifier = container.read(authProvider.notifier);

        await waitForAuth(container);

        final result = await notifier.loginWithEmail(
          'test@example.com',
          'temppass123',
        );

        // Wait for async state updates to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(result.isSuccess, true);

        final state = container.read(authProvider);
        expect(state, isA<AuthStateMustChangePassword>());
        expect(state.needsPasswordChange, true);
        expect(state.memberId, 'member_456');

        verify(() => mockStorage.saveEmail('test@example.com')).called(1);
        verify(() => mockStorage.saveTokens(any())).called(1);
      },
    );

    test(
      'loginWithEmail sets pendingPinSetup when no PIN and no password change needed',
      () async {
        when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
        when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const Result.success(testMemberLoginResponse),
        );
        when(
          () => mockStorage.saveEmail('test@example.com'),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.savePassword('password123'),
        ).thenAnswer((_) async {});
        when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
        when(() => mockStorage.getPin()).thenAnswer((_) async => null);

        final container = createContainer();
        final notifier = container.read(authProvider.notifier);

        await waitForAuth(container);

        final result = await notifier.loginWithEmail(
          'test@example.com',
          'password123',
        );

        // Wait for async state updates to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(result.isSuccess, true);

        final state = container.read(authProvider);
        expect(state, isA<AuthStatePendingPinSetup>());
        expect(state.needsPinSetup, true);
        expect(state.memberId, 'member_456');
      },
    );

    test('loginWithEmail completes to authenticated when PIN exists', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginWithEmail(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Result.success(testMemberLoginResponse));
      when(
        () => mockStorage.saveEmail('test@example.com'),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.savePassword('password123'),
      ).thenAnswer((_) async {});
      when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
      when(() => mockStorage.getPin()).thenAnswer((_) async => '1234');
      when(() => mockRepository.getMe()).thenAnswer(
        (_) async => const Result.success(testMemberProfileResponse),
      );
      when(() => mockStorage.saveProfile(any())).thenAnswer((_) async {});
      when(
        () => mockAuthApi.getSector('sector_1'),
      ).thenAnswer((_) async => testSector);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      await waitForAuth(container);

      await notifier.loginWithEmail('test@example.com', 'password123');

      // Wait for async profile fetch
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.profileOrNull?.firstName, 'John');
    });

    test(
      'loginWithEmail returns failure result without changing auth state',
      () async {
        when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
        when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginWithEmail(
            email: 'test@example.com',
            password: 'wrongpass',
          ),
        ).thenAnswer(
          (_) async => const Result.failure(
            AppError.unauthorized(message: 'Invalid credentials'),
          ),
        );

        final container = createContainer();
        final notifier = container.read(authProvider.notifier);

        await waitForAuth(container);

        // Verify initial state is unauthenticated
        expect(container.read(authProvider), isA<AuthStateUnauthenticated>());

        final result = await notifier.loginWithEmail(
          'test@example.com',
          'wrongpass',
        );

        // Result should be failure with error message
        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Invalid credentials');

        // Auth state should remain unauthenticated (not change to error state)
        // This allows the page to handle error display without router interference
        final state = container.read(authProvider);
        expect(state, isA<AuthStateUnauthenticated>());
      },
    );

    test(
      'changePassword transitions from mustChangePassword to pendingPinSetup',
      () async {
        when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
        when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
        when(
          () => mockRepository.loginWithEmail(
            email: 'test@example.com',
            password: 'temppass123',
          ),
        ).thenAnswer(
          (_) async => const Result.success(testMemberLoginResponseMustChange),
        );
        when(
          () => mockStorage.saveEmail('test@example.com'),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.savePassword('temppass123'),
        ).thenAnswer((_) async {});
        when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
        when(
          () => mockRepository.changePassword(
            currentPassword: 'temppass123',
            newPassword: 'NewPassword123!',
          ),
        ).thenAnswer((_) async => const Result.success(null));

        final container = createContainer();
        final notifier = container.read(authProvider.notifier);

        await waitForAuth(container);

        // First login with must change password
        await notifier.loginWithEmail('test@example.com', 'temppass123');
        // Wait for async state updates to complete
        await Future.delayed(const Duration(milliseconds: 50));
        expect(
          container.read(authProvider),
          isA<AuthStateMustChangePassword>(),
        );

        // Change password
        final result = await notifier.changePassword(
          'temppass123',
          'NewPassword123!',
        );

        expect(result.isSuccess, true);

        final state = container.read(authProvider);
        expect(state, isA<AuthStatePendingPinSetup>());
        expect(state.needsPinSetup, true);
      },
    );

    test('changePassword fails when not in mustChangePassword state', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      await waitForAuth(container);

      // Should be unauthenticated
      expect(container.read(authProvider), isA<AuthStateUnauthenticated>());

      // Try to change password - should fail
      final result = await notifier.changePassword('oldpass', 'newpass');

      expect(result.isFailure, true);
      expect(
        result.errorOrNull?.displayMessage,
        'Must be in password change state',
      );
    });

    test('completePinSetup transitions to authenticated', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockRepository.loginWithEmail(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Result.success(testMemberLoginResponse));
      when(
        () => mockStorage.saveEmail('test@example.com'),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.savePassword('password123'),
      ).thenAnswer((_) async {});
      when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
      when(() => mockStorage.getPin()).thenAnswer((_) async => null);
      when(() => mockStorage.savePin('1234')).thenAnswer((_) async {});
      when(() => mockRepository.getMe()).thenAnswer(
        (_) async => const Result.success(testMemberProfileResponse),
      );
      when(() => mockStorage.saveProfile(any())).thenAnswer((_) async {});
      when(
        () => mockAuthApi.getSector('sector_1'),
      ).thenAnswer((_) async => testSector);

      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      await waitForAuth(container);

      // Login without PIN
      await notifier.loginWithEmail('test@example.com', 'password123');
      // Wait for async state updates to complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(authProvider), isA<AuthStatePendingPinSetup>());

      // Complete PIN setup
      await notifier.completePinSetup('1234');

      // Wait for async profile fetch
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.profileOrNull?.firstName, 'John');

      verify(() => mockStorage.savePin('1234')).called(1);
    });

    test(
      'completePinSetup does nothing when not in pendingPinSetup state',
      () async {
        when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
        when(() => mockStorage.getProfile()).thenAnswer((_) async => null);

        final container = createContainer();
        final notifier = container.read(authProvider.notifier);

        await waitForAuth(container);

        // Should be unauthenticated
        expect(container.read(authProvider), isA<AuthStateUnauthenticated>());

        // Try to complete PIN setup - should do nothing
        await notifier.completePinSetup('1234');

        // State should still be unauthenticated
        expect(container.read(authProvider), isA<AuthStateUnauthenticated>());

        verifyNever(() => mockStorage.savePin(any()));
      },
    );

    test('storedEmailProvider returns stored email', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(
        () => mockStorage.getEmail(),
      ).thenAnswer((_) async => 'saved@example.com');

      final container = createContainer();

      await waitForAuth(container);

      final email = await container.read(storedEmailProvider.future);
      expect(email, 'saved@example.com');
    });

    test('storedEmailProvider returns null when no email stored', () async {
      when(() => mockStorage.getTokens()).thenAnswer((_) async => null);
      when(() => mockStorage.getProfile()).thenAnswer((_) async => null);
      when(() => mockStorage.getEmail()).thenAnswer((_) async => null);

      final container = createContainer();

      await waitForAuth(container);

      final email = await container.read(storedEmailProvider.future);
      expect(email, isNull);
    });
  });
}
