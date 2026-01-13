import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';

void main() {
  group('AuthTokens', () {
    test('can be created with tokens', () {
      const tokens = AuthTokens(
        accessToken: 'access_abc123',
        refreshToken: 'refresh_xyz789',
      );

      expect(tokens.accessToken, 'access_abc123');
      expect(tokens.refreshToken, 'refresh_xyz789');
      expect(tokens.expiresAt, isNull);
    });

    test('can be created with optional expiresAt', () {
      const tokens = AuthTokens(
        accessToken: 'access_abc123',
        refreshToken: 'refresh_xyz789',
        expiresAt: '2024-12-31T23:59:59Z',
      );

      expect(tokens.expiresAt, '2024-12-31T23:59:59Z');
    });

    group('fromMemberLoginResponse factory', () {
      test('creates tokens with calculated expiresAt', () {
        final tokens = AuthTokens.fromMemberLoginResponse(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 900,
        );

        expect(tokens.accessToken, 'access-token');
        expect(tokens.refreshToken, 'refresh-token');
        expect(tokens.expiresAt, isNotNull);

        // Verify the expiresAt is a valid ISO 8601 string
        final expiresAtDate = DateTime.parse(tokens.expiresAt!);
        final now = DateTime.now();

        // Should be approximately 900 seconds (15 minutes) from now
        // Allow some tolerance for test execution time
        final difference = expiresAtDate.difference(now).inSeconds;
        expect(difference, greaterThanOrEqualTo(895));
        expect(difference, lessThanOrEqualTo(905));
      });

      test('handles various expiresIn values', () {
        // 1 hour
        final tokens1 = AuthTokens.fromMemberLoginResponse(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 3600,
        );
        expect(tokens1.expiresAt, isNotNull);

        final expiresAt1 = DateTime.parse(tokens1.expiresAt!);
        final diff1 = expiresAt1.difference(DateTime.now()).inSeconds;
        expect(diff1, greaterThanOrEqualTo(3595));

        // 24 hours
        final tokens2 = AuthTokens.fromMemberLoginResponse(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 86400,
        );
        expect(tokens2.expiresAt, isNotNull);

        final expiresAt2 = DateTime.parse(tokens2.expiresAt!);
        final diff2 = expiresAt2.difference(DateTime.now()).inSeconds;
        expect(diff2, greaterThanOrEqualTo(86395));
      });
    });

    test('toJson serializes correctly', () {
      const tokens = AuthTokens(
        accessToken: 'access_abc123',
        refreshToken: 'refresh_xyz789',
        expiresAt: '2024-12-31T23:59:59Z',
      );

      expect(tokens.toJson(), {
        'accessToken': 'access_abc123',
        'refreshToken': 'refresh_xyz789',
        'expiresAt': '2024-12-31T23:59:59Z',
      });
    });

    test('fromJson deserializes correctly', () {
      final tokens = AuthTokens.fromJson({
        'accessToken': 'access_abc123',
        'refreshToken': 'refresh_xyz789',
        'expiresAt': '2024-12-31T23:59:59Z',
      });

      expect(tokens.accessToken, 'access_abc123');
      expect(tokens.refreshToken, 'refresh_xyz789');
      expect(tokens.expiresAt, '2024-12-31T23:59:59Z');
    });

    test('equality works correctly', () {
      const tokens1 = AuthTokens(
        accessToken: 'access_abc123',
        refreshToken: 'refresh_xyz789',
      );
      const tokens2 = AuthTokens(
        accessToken: 'access_abc123',
        refreshToken: 'refresh_xyz789',
      );
      const tokens3 = AuthTokens(
        accessToken: 'different',
        refreshToken: 'refresh_xyz789',
      );

      expect(tokens1, tokens2);
      expect(tokens1, isNot(tokens3));
    });
  });
}
