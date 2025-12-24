import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

void main() {
  group('LoginRequest', () {
    test('can be created with phone and pin', () {
      const request = LoginRequest(
        phoneNumber: '+27821234567',
        pin: '1234',
      );

      expect(request.phoneNumber, '+27821234567');
      expect(request.pin, '1234');
    });

    test('toJson serializes correctly', () {
      const request = LoginRequest(
        phoneNumber: '+27821234567',
        pin: '1234',
      );

      expect(request.toJson(), {
        'phoneNumber': '+27821234567',
        'pin': '1234',
      });
    });

    test('fromJson deserializes correctly', () {
      final request = LoginRequest.fromJson({
        'phoneNumber': '+27821234567',
        'pin': '1234',
      });

      expect(request.phoneNumber, '+27821234567');
      expect(request.pin, '1234');
    });

    test('equality works correctly', () {
      const request1 = LoginRequest(phoneNumber: '+27821234567', pin: '1234');
      const request2 = LoginRequest(phoneNumber: '+27821234567', pin: '1234');
      const request3 = LoginRequest(phoneNumber: '+27821234567', pin: '5678');

      expect(request1, request2);
      expect(request1, isNot(request3));
    });
  });

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

    test('toJson serializes correctly without expiresAt', () {
      const tokens = AuthTokens(
        accessToken: 'access_abc123',
        refreshToken: 'refresh_xyz789',
      );

      expect(tokens.toJson(), {
        'accessToken': 'access_abc123',
        'refreshToken': 'refresh_xyz789',
        'expiresAt': null,
      });
    });

    test('toJson serializes correctly with expiresAt', () {
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
  });

  group('MemberProfile', () {
    test('can be created with required fields', () {
      const profile = MemberProfile(
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

      expect(profile.id, 'user_123');
      expect(profile.firstName, 'John');
      expect(profile.surname, 'Doe');
      expect(profile.phoneNumber, '+27821234567');
      expect(profile.address, '123 Test Street');
      expect(profile.sectorId, 'sector_1');
      expect(profile.status, 'active');
    });

    test('fullName returns combined name', () {
      const profile = MemberProfile(
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

      expect(profile.fullName, 'John Doe');
    });

    test('fromJson deserializes correctly', () {
      final profile = MemberProfile.fromJson({
        'id': 'user_123',
        'firstName': 'John',
        'surname': 'Doe',
        'phoneNumber': '+27821234567',
        'address': '123 Test Street',
        'registrationLocation': {'latitude': -26.2, 'longitude': 28.0},
        'sectorId': 'sector_1',
        'status': 'active',
        'createdAt': '2024-01-01T00:00:00Z',
      });

      expect(profile.id, 'user_123');
      expect(profile.firstName, 'John');
      expect(profile.registrationLocation.latitude, -26.2);
    });
  });

  group('SectorInfo', () {
    test('can be created with required fields', () {
      const sector = SectorInfo(
        id: 'sector_1',
        name: 'Test Sector',
        center: GeoPoint(latitude: -26.2, longitude: 28.0),
      );

      expect(sector.id, 'sector_1');
      expect(sector.name, 'Test Sector');
      expect(sector.center.latitude, -26.2);
    });

    test('fromJson deserializes correctly', () {
      final sector = SectorInfo.fromJson({
        'id': 'sector_1',
        'name': 'Test Sector',
        'center': {'latitude': -26.2, 'longitude': 28.0},
      });

      expect(sector.id, 'sector_1');
      expect(sector.name, 'Test Sector');
    });
  });

  group('AuthProfile', () {
    const testMember = MemberProfile(
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

    test('can be created with member and sector', () {
      const profile = AuthProfile(
        member: testMember,
        sector: testSector,
      );

      expect(profile.member.firstName, 'John');
      expect(profile.sector.name, 'Test Sector');
    });

    test('fromJson deserializes correctly', () {
      final profile = AuthProfile.fromJson({
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
      });

      expect(profile.member.firstName, 'John');
      expect(profile.sector.name, 'Test Sector');
    });
  });

  group('AuthResponse', () {
    const testTokens = AuthTokens(
      accessToken: 'access_abc123',
      refreshToken: 'refresh_xyz789',
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
      const response = AuthResponse(
        tokens: testTokens,
        profile: testProfile,
      );

      expect(response.tokens.accessToken, 'access_abc123');
      expect(response.profile.member.firstName, 'John');
      expect(response.profile.sector.name, 'Test Sector');
    });

    test('convenience accessors work', () {
      const response = AuthResponse(
        tokens: testTokens,
        profile: testProfile,
      );

      expect(response.member.firstName, 'John');
      expect(response.sector.name, 'Test Sector');
    });

    test('fromJson deserializes correctly', () {
      final response = AuthResponse.fromJson({
        'tokens': {
          'accessToken': 'access_abc123',
          'refreshToken': 'refresh_xyz789',
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

      expect(response.tokens.accessToken, 'access_abc123');
      expect(response.tokens.refreshToken, 'refresh_xyz789');
      expect(response.profile.member.id, 'user_123');
      expect(response.profile.member.firstName, 'John');
      expect(response.profile.sector.name, 'Test Sector');
    });
  });

  group('UserProfile typedef', () {
    test('UserProfile is alias for MemberProfile', () {
      const profile = UserProfile(
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

      expect(profile, isA<MemberProfile>());
      expect(profile.fullName, 'John Doe');
    });
  });
}
