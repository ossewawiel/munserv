import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(mockStorage);
  });

  group('SecureStorageService', () {
    group('tokens', () {
      test('saveTokens stores both tokens', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.saveTokens(const AuthTokens(
          accessToken: 'access_abc',
          refreshToken: 'refresh_xyz',
        ));

        verify(() => mockStorage.write(
              key: SecureStorageKeys.accessToken,
              value: 'access_abc',
            )).called(1);
        verify(() => mockStorage.write(
              key: SecureStorageKeys.refreshToken,
              value: 'refresh_xyz',
            )).called(1);
      });

      test('getTokens returns tokens when stored', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
            .thenAnswer((_) async => 'access_abc');
        when(() => mockStorage.read(key: SecureStorageKeys.refreshToken))
            .thenAnswer((_) async => 'refresh_xyz');

        final tokens = await service.getTokens();

        expect(tokens?.accessToken, 'access_abc');
        expect(tokens?.refreshToken, 'refresh_xyz');
      });

      test('getTokens returns null when no tokens stored', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
            .thenAnswer((_) async => null);
        when(() => mockStorage.read(key: SecureStorageKeys.refreshToken))
            .thenAnswer((_) async => null);

        final tokens = await service.getTokens();

        expect(tokens, isNull);
      });

      test('getAccessToken returns stored access token', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
            .thenAnswer((_) async => 'access_abc');

        final token = await service.getAccessToken();

        expect(token, 'access_abc');
      });

      test('clearTokens removes all tokens', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.clearTokens();

        verify(() => mockStorage.delete(key: SecureStorageKeys.accessToken))
            .called(1);
        verify(() => mockStorage.delete(key: SecureStorageKeys.refreshToken))
            .called(1);
      });
    });

    group('profile', () {
      test('saveProfile stores profile as JSON', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        const profile = UserProfile(
          id: 'user_123',
          phoneNumber: '+27821234567',
          firstName: 'John',
          surname: 'Doe',
          address: '123 Test Street',
          registrationLocation: GeoPoint(latitude: -26.2, longitude: 28.0),
          sectorId: 'sector_1',
          status: 'active',
          createdAt: '2024-01-01T00:00:00Z',
        );

        await service.saveProfile(profile);

        verify(() => mockStorage.write(
              key: SecureStorageKeys.userProfile,
              value: jsonEncode(profile.toJson()),
            )).called(1);
      });

      test('getProfile returns profile when stored', () async {
        final profileJson = jsonEncode({
          'id': 'user_123',
          'phoneNumber': '+27821234567',
          'firstName': 'John',
          'surname': 'Doe',
          'address': '123 Test Street',
          'registrationLocation': {'latitude': -26.2, 'longitude': 28.0},
          'sectorId': 'sector_1',
          'status': 'active',
          'createdAt': '2024-01-01T00:00:00Z',
        });
        when(() => mockStorage.read(key: SecureStorageKeys.userProfile))
            .thenAnswer((_) async => profileJson);

        final profile = await service.getProfile();

        expect(profile?.id, 'user_123');
        expect(profile?.firstName, 'John');
        expect(profile?.surname, 'Doe');
      });

      test('getProfile returns null when no profile stored', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.userProfile))
            .thenAnswer((_) async => null);

        final profile = await service.getProfile();

        expect(profile, isNull);
      });

      test('clearProfile removes profile', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.clearProfile();

        verify(() => mockStorage.delete(key: SecureStorageKeys.userProfile))
            .called(1);
      });
    });

    group('phone number', () {
      test('savePhoneNumber stores phone number', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.savePhoneNumber('+27821234567');

        verify(() => mockStorage.write(
              key: SecureStorageKeys.phoneNumber,
              value: '+27821234567',
            )).called(1);
      });

      test('getPhoneNumber returns stored phone number', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.phoneNumber))
            .thenAnswer((_) async => '+27821234567');

        final phone = await service.getPhoneNumber();

        expect(phone, '+27821234567');
      });
    });

    group('clearAll', () {
      test('clears all stored data', () async {
        when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

        await service.clearAll();

        verify(() => mockStorage.deleteAll()).called(1);
      });
    });

    group('hasValidSession', () {
      test('returns true when access token exists', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
            .thenAnswer((_) async => 'access_abc');

        final hasSession = await service.hasValidSession();

        expect(hasSession, true);
      });

      test('returns false when no access token', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
            .thenAnswer((_) async => null);

        final hasSession = await service.hasValidSession();

        expect(hasSession, false);
      });
    });
  });
}
