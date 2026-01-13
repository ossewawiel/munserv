import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';
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

        const profile = MemberProfile(
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

    group('email', () {
      test('saveEmail stores email address', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.saveEmail('test@example.com');

        verify(() => mockStorage.write(
              key: SecureStorageKeys.email,
              value: 'test@example.com',
            )).called(1);
      });

      test('getEmail returns stored email', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.email))
            .thenAnswer((_) async => 'test@example.com');

        final email = await service.getEmail();

        expect(email, 'test@example.com');
      });

      test('getEmail returns null when no email stored', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.email))
            .thenAnswer((_) async => null);

        final email = await service.getEmail();

        expect(email, isNull);
      });
    });

    group('PIN', () {
      test('savePin stores PIN', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.savePin('1234');

        verify(() => mockStorage.write(
              key: SecureStorageKeys.pin,
              value: '1234',
            )).called(1);
      });

      test('getPin returns stored PIN', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.pin))
            .thenAnswer((_) async => '1234');

        final pin = await service.getPin();

        expect(pin, '1234');
      });

      test('getPin returns null when no PIN stored', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.pin))
            .thenAnswer((_) async => null);

        final pin = await service.getPin();

        expect(pin, isNull);
      });

      test('clearPin removes PIN', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.clearPin();

        verify(() => mockStorage.delete(key: SecureStorageKeys.pin))
            .called(1);
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

    group('password storage (for quick login)', () {
      test('savePassword stores password', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.savePassword('securePass123');

        verify(() => mockStorage.write(
              key: SecureStorageKeys.password,
              value: 'securePass123',
            )).called(1);
      });

      test('getPassword returns stored password', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.password))
            .thenAnswer((_) async => 'securePass123');

        final password = await service.getPassword();

        expect(password, 'securePass123');
      });

      test('getPassword returns null when no password stored', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.password))
            .thenAnswer((_) async => null);

        final password = await service.getPassword();

        expect(password, isNull);
      });

      test('clearPassword removes stored password', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.clearPassword();

        verify(() => mockStorage.delete(key: SecureStorageKeys.password))
            .called(1);
      });
    });

    group('quick login eligibility', () {
      test('hasQuickLoginCredentials returns true when all credentials present',
          () async {
        when(() => mockStorage.read(key: SecureStorageKeys.email))
            .thenAnswer((_) async => 'test@example.com');
        when(() => mockStorage.read(key: SecureStorageKeys.password))
            .thenAnswer((_) async => 'securePass123');
        when(() => mockStorage.read(key: SecureStorageKeys.pin))
            .thenAnswer((_) async => '1234');

        final hasCredentials = await service.hasQuickLoginCredentials();

        expect(hasCredentials, true);
      });

      test('hasQuickLoginCredentials returns false when email missing',
          () async {
        when(() => mockStorage.read(key: SecureStorageKeys.email))
            .thenAnswer((_) async => null);
        when(() => mockStorage.read(key: SecureStorageKeys.password))
            .thenAnswer((_) async => 'securePass123');
        when(() => mockStorage.read(key: SecureStorageKeys.pin))
            .thenAnswer((_) async => '1234');

        final hasCredentials = await service.hasQuickLoginCredentials();

        expect(hasCredentials, false);
      });

      test('hasQuickLoginCredentials returns false when password missing',
          () async {
        when(() => mockStorage.read(key: SecureStorageKeys.email))
            .thenAnswer((_) async => 'test@example.com');
        when(() => mockStorage.read(key: SecureStorageKeys.password))
            .thenAnswer((_) async => null);
        when(() => mockStorage.read(key: SecureStorageKeys.pin))
            .thenAnswer((_) async => '1234');

        final hasCredentials = await service.hasQuickLoginCredentials();

        expect(hasCredentials, false);
      });

      test('hasQuickLoginCredentials returns false when PIN missing', () async {
        when(() => mockStorage.read(key: SecureStorageKeys.email))
            .thenAnswer((_) async => 'test@example.com');
        when(() => mockStorage.read(key: SecureStorageKeys.password))
            .thenAnswer((_) async => 'securePass123');
        when(() => mockStorage.read(key: SecureStorageKeys.pin))
            .thenAnswer((_) async => null);

        final hasCredentials = await service.hasQuickLoginCredentials();

        expect(hasCredentials, false);
      });
    });

    group('clearQuickLoginData', () {
      test('clears password and session but keeps email for convenience',
          () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.clearQuickLoginData();

        verify(() => mockStorage.delete(key: SecureStorageKeys.password))
            .called(1);
        verify(() => mockStorage.delete(key: SecureStorageKeys.pin)).called(1);
        verify(() => mockStorage.delete(key: SecureStorageKeys.biometricPin))
            .called(1);
        verify(() => mockStorage.delete(key: SecureStorageKeys.accessToken))
            .called(1);
        verify(() => mockStorage.delete(key: SecureStorageKeys.refreshToken))
            .called(1);
        // Email should NOT be deleted - user can re-login with same email
        verifyNever(() => mockStorage.delete(key: SecureStorageKeys.email));
      });
    });
  });
}
