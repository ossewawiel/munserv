import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/auth_state.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

void main() {
  // Test fixtures
  const testTokens = AuthTokens(
    accessToken: 'access_abc123',
    refreshToken: 'refresh_xyz789',
  );

  const testProfile = MemberProfile(
    id: 'user_123',
    firstName: 'John',
    surname: 'Doe',
    phoneNumber: '+27821234567',
    address: '123 Test Street',
    registrationLocation: GeoPoint(latitude: -26.2, longitude: 28.0),
    sectorId: 'sector_1',
    status: 'active',
    createdAt: '2024-01-01T00:00:00Z',
  );

  const testSector = SectorInfo(
    id: 'sector_1',
    name: 'Test Sector',
    center: GeoPoint(latitude: -26.2, longitude: 28.0),
  );

  group('AuthState', () {
    group('initial state', () {
      test('can be created', () {
        const state = AuthState.initial();
        expect(state, isA<AuthStateInitial>());
      });
    });

    group('loading state', () {
      test('can be created', () {
        const state = AuthState.loading();
        expect(state, isA<AuthStateLoading>());
      });
    });

    group('unauthenticated state', () {
      test('can be created', () {
        const state = AuthState.unauthenticated();
        expect(state, isA<AuthStateUnauthenticated>());
      });
    });

    group('authenticated state', () {
      test('can be created with tokens, profile, and sector', () {
        const state = AuthState.authenticated(
          tokens: testTokens,
          profile: testProfile,
          sector: testSector,
        );

        expect(state, isA<AuthStateAuthenticated>());
        final authenticated = state as AuthStateAuthenticated;
        expect(authenticated.tokens.accessToken, 'access_abc123');
        expect(authenticated.profile.firstName, 'John');
        expect(authenticated.sector.name, 'Test Sector');
      });
    });

    group('error state', () {
      test('can be created with message', () {
        const state = AuthState.error('Authentication failed');
        expect(state, isA<AuthStateError>());
        final error = state as AuthStateError;
        expect(error.message, 'Authentication failed');
      });
    });

    group('mustChangePassword state', () {
      test('can be created with tokens and memberId', () {
        const state = AuthState.mustChangePassword(
          tokens: testTokens,
          memberId: 'member_123',
        );

        expect(state, isA<AuthStateMustChangePassword>());
        final mustChange = state as AuthStateMustChangePassword;
        expect(mustChange.tokens.accessToken, 'access_abc123');
        expect(mustChange.memberId, 'member_123');
      });
    });

    group('pendingPinSetup state', () {
      test('can be created with tokens and memberId', () {
        const state = AuthState.pendingPinSetup(
          tokens: testTokens,
          memberId: 'member_123',
        );

        expect(state, isA<AuthStatePendingPinSetup>());
        final pending = state as AuthStatePendingPinSetup;
        expect(pending.tokens.accessToken, 'access_abc123');
        expect(pending.memberId, 'member_123');
      });
    });
  });

  group('AuthStateX extension', () {
    group('isAuthenticated', () {
      test('returns true for authenticated state', () {
        const state = AuthState.authenticated(
          tokens: testTokens,
          profile: testProfile,
          sector: testSector,
        );
        expect(state.isAuthenticated, true);
      });

      test('returns false for other states', () {
        expect(const AuthState.initial().isAuthenticated, false);
        expect(const AuthState.loading().isAuthenticated, false);
        expect(const AuthState.unauthenticated().isAuthenticated, false);
        expect(const AuthState.error('error').isAuthenticated, false);
        expect(
          const AuthState.mustChangePassword(
            tokens: testTokens,
            memberId: '123',
          ).isAuthenticated,
          false,
        );
        expect(
          const AuthState.pendingPinSetup(
            tokens: testTokens,
            memberId: '123',
          ).isAuthenticated,
          false,
        );
      });
    });

    group('isLoading', () {
      test('returns true for initial and loading states', () {
        expect(const AuthState.initial().isLoading, true);
        expect(const AuthState.loading().isLoading, true);
      });

      test('returns false for other states', () {
        expect(const AuthState.unauthenticated().isLoading, false);
        expect(const AuthState.error('error').isLoading, false);
        expect(
          const AuthState.authenticated(
            tokens: testTokens,
            profile: testProfile,
            sector: testSector,
          ).isLoading,
          false,
        );
      });
    });

    group('needsPasswordChange', () {
      test('returns true for mustChangePassword state', () {
        const state = AuthState.mustChangePassword(
          tokens: testTokens,
          memberId: '123',
        );
        expect(state.needsPasswordChange, true);
      });

      test('returns false for other states', () {
        expect(const AuthState.initial().needsPasswordChange, false);
        expect(const AuthState.loading().needsPasswordChange, false);
        expect(const AuthState.unauthenticated().needsPasswordChange, false);
        expect(const AuthState.error('error').needsPasswordChange, false);
        expect(
          const AuthState.authenticated(
            tokens: testTokens,
            profile: testProfile,
            sector: testSector,
          ).needsPasswordChange,
          false,
        );
        expect(
          const AuthState.pendingPinSetup(
            tokens: testTokens,
            memberId: '123',
          ).needsPasswordChange,
          false,
        );
      });
    });

    group('needsPinSetup', () {
      test('returns true for pendingPinSetup state', () {
        const state = AuthState.pendingPinSetup(
          tokens: testTokens,
          memberId: '123',
        );
        expect(state.needsPinSetup, true);
      });

      test('returns false for other states', () {
        expect(const AuthState.initial().needsPinSetup, false);
        expect(const AuthState.loading().needsPinSetup, false);
        expect(const AuthState.unauthenticated().needsPinSetup, false);
        expect(const AuthState.error('error').needsPinSetup, false);
        expect(
          const AuthState.authenticated(
            tokens: testTokens,
            profile: testProfile,
            sector: testSector,
          ).needsPinSetup,
          false,
        );
        expect(
          const AuthState.mustChangePassword(
            tokens: testTokens,
            memberId: '123',
          ).needsPinSetup,
          false,
        );
      });
    });

    group('tokens getter', () {
      test('returns tokens for authenticated state', () {
        const state = AuthState.authenticated(
          tokens: testTokens,
          profile: testProfile,
          sector: testSector,
        );
        expect(state.tokens, testTokens);
      });

      test('returns tokens for mustChangePassword state', () {
        const state = AuthState.mustChangePassword(
          tokens: testTokens,
          memberId: '123',
        );
        expect(state.tokens, testTokens);
      });

      test('returns tokens for pendingPinSetup state', () {
        const state = AuthState.pendingPinSetup(
          tokens: testTokens,
          memberId: '123',
        );
        expect(state.tokens, testTokens);
      });

      test('returns null for other states', () {
        expect(const AuthState.initial().tokens, isNull);
        expect(const AuthState.loading().tokens, isNull);
        expect(const AuthState.unauthenticated().tokens, isNull);
        expect(const AuthState.error('error').tokens, isNull);
      });
    });

    group('memberId getter', () {
      test('returns memberId for authenticated state (from profile)', () {
        const state = AuthState.authenticated(
          tokens: testTokens,
          profile: testProfile,
          sector: testSector,
        );
        expect(state.memberId, 'user_123');
      });

      test('returns memberId for mustChangePassword state', () {
        const state = AuthState.mustChangePassword(
          tokens: testTokens,
          memberId: 'member_123',
        );
        expect(state.memberId, 'member_123');
      });

      test('returns memberId for pendingPinSetup state', () {
        const state = AuthState.pendingPinSetup(
          tokens: testTokens,
          memberId: 'member_456',
        );
        expect(state.memberId, 'member_456');
      });

      test('returns null for other states', () {
        expect(const AuthState.initial().memberId, isNull);
        expect(const AuthState.loading().memberId, isNull);
        expect(const AuthState.unauthenticated().memberId, isNull);
        expect(const AuthState.error('error').memberId, isNull);
      });
    });
  });
}
