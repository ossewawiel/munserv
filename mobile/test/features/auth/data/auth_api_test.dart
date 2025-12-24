import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';
import 'package:munserv_mobile/features/auth/domain/registration_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

class MockDio extends Mock implements Dio {}

/// Test data for auth responses
final testProfileData = {
  'member': {
    'id': 'user_123',
    'firstName': 'John',
    'surname': 'Doe',
    'phoneNumber': '+27821234567',
    'address': '42 Doreen Road, Northcliff',
    'registrationLocation': {'latitude': -26.135, 'longitude': 27.98},
    'sectorId': 'sector_1',
    'status': 'active',
    'createdAt': '2024-01-01T00:00:00Z',
  },
  'sector': {
    'id': 'sector_1',
    'name': 'Northcliff',
    'center': {'latitude': -26.135, 'longitude': 27.98},
  },
};

void main() {
  late MockDio mockDio;
  late AuthApi authApi;

  setUp(() {
    mockDio = MockDio();
    authApi = AuthApi(mockDio);
  });

  group('AuthApi', () {
    group('requestOtp', () {
      test('calls POST /auth/register with phone number', () async {
        when(() => mockDio.post(
              '/auth/register',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {'message': 'OTP sent', 'expiresInSeconds': 300},
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27821234567'),
        );

        expect(result.message, 'OTP sent');
        expect(result.expiresInSeconds, 300);
        verify(() => mockDio.post(
              '/auth/register',
              data: {'phoneNumber': '+27821234567'},
            )).called(1);
      });
    });

    group('verifyOtp', () {
      test('calls POST /auth/verify-otp and returns NewUser', () async {
        when(() => mockDio.post(
              '/auth/verify-otp',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {'status': 'new_user', 'tempToken': 'temp_abc123'},
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
        );

        expect(result, isA<OtpVerifyResultNewUser>());
        expect((result as OtpVerifyResultNewUser).tempToken, 'temp_abc123');
        verify(() => mockDio.post(
              '/auth/verify-otp',
              data: {'phoneNumber': '+27821234567', 'otp': '123456'},
            )).called(1);
      });

      test('calls POST /auth/verify-otp and returns ExistingUser', () async {
        when(() => mockDio.post(
              '/auth/verify-otp',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'status': 'existing_user',
                'tokens': {
                  'accessToken': 'access_abc',
                  'refreshToken': 'refresh_xyz',
                },
                'profile': testProfileData,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
        );

        expect(result, isA<OtpVerifyResultExistingUser>());
        final existing = result as OtpVerifyResultExistingUser;
        expect(existing.tokens.accessToken, 'access_abc');
        expect(existing.profile.member.id, 'user_123');
      });
    });

    group('completeRegistration', () {
      test('calls POST /auth/complete-registration with auth header', () async {
        when(() => mockDio.post(
              '/auth/complete-registration',
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              data: {
                'tokens': {
                  'accessToken': 'access_abc',
                  'refreshToken': 'refresh_xyz',
                },
                'profile': testProfileData,
              },
              statusCode: 201,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.completeRegistration(
          tempToken: 'temp_abc123',
          request: const RegistrationRequest(
            firstName: 'John',
            surname: 'Doe',
            pin: '1234',
            location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
            address: '42 Doreen Road, Northcliff',
          ),
        );

        expect(result.tokens.accessToken, 'access_abc');
        expect(result.profile.member.firstName, 'John');

        final captured = verify(() => mockDio.post(
          '/auth/complete-registration',
          data: any(named: 'data'),
          options: captureAny(named: 'options'),
        )).captured;

        final options = captured.first as Options;
        expect(options.headers?['Authorization'], 'Bearer temp_abc123');
      });
    });

    group('login', () {
      test('calls POST /auth/login with credentials', () async {
        when(() => mockDio.post(
              '/auth/login',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'tokens': {
                  'accessToken': 'access_abc',
                  'refreshToken': 'refresh_xyz',
                },
                'profile': testProfileData,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.login(
          const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
        );

        expect(result.tokens.accessToken, 'access_abc');
        expect(result.tokens.refreshToken, 'refresh_xyz');
        expect(result.profile.member.id, 'user_123');
        verify(() => mockDio.post(
              '/auth/login',
              data: {'phoneNumber': '+27821234567', 'pin': '1234'},
            )).called(1);
      });
    });

    group('refreshToken', () {
      test('calls POST /auth/refresh with refresh token', () async {
        when(() => mockDio.post(
              '/auth/refresh',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'tokens': {
                  'accessToken': 'new_access_token',
                  'refreshToken': 'new_refresh_token',
                  'expiresAt': '2024-12-31T23:59:59Z',
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.refreshToken('old_refresh_token');

        expect(result.accessToken, 'new_access_token');
        expect(result.refreshToken, 'new_refresh_token');
        verify(() => mockDio.post(
              '/auth/refresh',
              data: {'refreshToken': 'old_refresh_token'},
            )).called(1);
      });
    });
  });
}
