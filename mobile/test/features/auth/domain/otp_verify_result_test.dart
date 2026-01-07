import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

void main() {
  group('OtpVerifyRequest', () {
    test('can be created with phone and otp', () {
      const request = OtpVerifyRequest(
        phoneNumber: '+27821234567',
        otp: '123456',
      );

      expect(request.phoneNumber, '+27821234567');
      expect(request.otp, '123456');
    });

    test('toJson serializes correctly', () {
      const request = OtpVerifyRequest(
        phoneNumber: '+27821234567',
        otp: '123456',
      );

      expect(request.toJson(), {
        'phoneNumber': '+27821234567',
        'otp': '123456',
      });
    });
  });

  group('OtpVerifyResult', () {
    group('NewUser', () {
      test('can be created with tempToken', () {
        const result = OtpVerifyResult.newUser(tempToken: 'temp_abc123');

        expect(result, isA<OtpVerifyResultNewUser>());
        expect((result as OtpVerifyResultNewUser).tempToken, 'temp_abc123');
      });

      test('isNewUser returns true', () {
        const result = OtpVerifyResult.newUser(tempToken: 'temp_abc123');

        expect(result.isNewUser, true);
        expect(result.isExistingUser, false);
      });

      test('fromJson deserializes new_user correctly', () {
        final result = OtpVerifyResult.fromJson({
          'status': 'new_user',
          'tempToken': 'temp_abc123',
        });

        expect(result, isA<OtpVerifyResultNewUser>());
        expect((result as OtpVerifyResultNewUser).tempToken, 'temp_abc123');
      });
    });

    group('ExistingUser', () {
      const testTokens = AuthTokens(
        accessToken: 'access_abc',
        refreshToken: 'refresh_xyz',
        expiresAt: '2024-12-31T23:59:59Z',
      );

      const testProfile = AuthProfile(
        member: MemberProfile(
          id: 'user_123',
          firstName: 'John',
          surname: 'Doe',
          phoneNumber: '+27821234567',
          address: '123 Test Street',
          registrationLocation: GeoPoint(latitude: -26.2, longitude: 28.0),
          sectorId: 'sector_1',
          status: 'active',
          createdAt: '2024-01-01T00:00:00Z',
        ),
        sector: SectorInfo(
          id: 'sector_1',
          name: 'Test Sector',
          center: GeoPoint(latitude: -26.2, longitude: 28.0),
        ),
      );

      test('can be created with tokens and profile', () {
        const result = OtpVerifyResult.existingUser(
          tokens: testTokens,
          profile: testProfile,
        );

        expect(result, isA<OtpVerifyResultExistingUser>());
        final existing = result as OtpVerifyResultExistingUser;
        expect(existing.tokens?.accessToken, 'access_abc');
        expect(existing.profile?.member.id, 'user_123');
      });

      test('can be created with null tokens and profile (backend flow)', () {
        const result = OtpVerifyResult.existingUser(
          tokens: null,
          profile: null,
        );

        expect(result, isA<OtpVerifyResultExistingUser>());
        final existing = result as OtpVerifyResultExistingUser;
        expect(existing.tokens, isNull);
        expect(existing.profile, isNull);
        expect(result.hasTokens, false);
      });

      test('isExistingUser returns true', () {
        const result = OtpVerifyResult.existingUser(
          tokens: testTokens,
          profile: testProfile,
        );

        expect(result.isNewUser, false);
        expect(result.isExistingUser, true);
      });

      test('fromJson deserializes existing_user correctly', () {
        final result = OtpVerifyResult.fromJson({
          'status': 'existing_user',
          'tokens': {
            'accessToken': 'access_abc',
            'refreshToken': 'refresh_xyz',
            'expiresAt': '2024-12-31T23:59:59Z',
          },
          'profile': {
            'member': {
              'id': 'user_123',
              'firstName': 'John',
              'surname': 'Doe',
              'phoneNumber': '+27821234567',
              'address': '123 Test Street',
              'registrationLocation': {'latitude': -26.2, 'longitude': 28.0},
              'sectorId': 'sector_1',
              'status': 'active',
              'createdAt': '2024-01-01T00:00:00Z',
            },
            'sector': {
              'id': 'sector_1',
              'name': 'Test Sector',
              'center': {'latitude': -26.2, 'longitude': 28.0},
            },
          },
        });

        expect(result, isA<OtpVerifyResultExistingUser>());
        final existing = result as OtpVerifyResultExistingUser;
        expect(existing.tokens?.accessToken, 'access_abc');
        expect(existing.profile?.member.firstName, 'John');
        expect(existing.profile?.sector.name, 'Test Sector');
      });
    });

    group('pattern matching', () {
      const testTokens = AuthTokens(
        accessToken: 'access_abc',
        refreshToken: 'refresh_xyz',
      );

      const testProfile = AuthProfile(
        member: MemberProfile(
          id: 'user_123',
          firstName: 'John',
          surname: 'Doe',
          phoneNumber: '+27821234567',
          address: '123 Test Street',
          registrationLocation: GeoPoint(latitude: -26.2, longitude: 28.0),
          sectorId: 'sector_1',
          status: 'active',
          createdAt: '2024-01-01T00:00:00Z',
        ),
        sector: SectorInfo(
          id: 'sector_1',
          name: 'Test Sector',
          center: GeoPoint(latitude: -26.2, longitude: 28.0),
        ),
      );

      test('can match on NewUser', () {
        const result = OtpVerifyResult.newUser(tempToken: 'temp_abc');

        final output = switch (result) {
          OtpVerifyResultNewUser(:final tempToken) => 'New: $tempToken',
          OtpVerifyResultExistingUser(:final profile) =>
            'Existing: ${profile?.member.id ?? "unknown"}',
        };

        expect(output, 'New: temp_abc');
      });

      test('can match on ExistingUser', () {
        const result = OtpVerifyResult.existingUser(
          tokens: testTokens,
          profile: testProfile,
        );

        final output = switch (result) {
          OtpVerifyResultNewUser(:final tempToken) => 'New: $tempToken',
          OtpVerifyResultExistingUser(:final profile) =>
            'Existing: ${profile?.member.id ?? "unknown"}',
        };

        expect(output, 'Existing: user_123');
      });
    });
  });
}
