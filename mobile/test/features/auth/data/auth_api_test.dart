import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/domain/backend_registration_request.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthApi authApi;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

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
              data: {'phone': '+27821234567'},
            )).called(1);
      });
    });

    group('verifyOtp', () {
      test('calls POST /auth/verify-otp with phone and code', () async {
        when(() => mockDio.post(
              '/auth/verify-otp',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {'message': 'OTP verified successfully'},
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        // verifyOtp now returns void
        await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
        );

        verify(() => mockDio.post(
              '/auth/verify-otp',
              data: {'phone': '+27821234567', 'code': '123456'},
            )).called(1);
      });
    });

    group('checkPhone', () {
      test('calls GET /auth/check-phone with phone number', () async {
        when(() => mockDio.get(
              '/auth/check-phone',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {'isRegistered': true},
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.checkPhone('+27821234567');

        expect(result.isRegistered, true);
        verify(() => mockDio.get(
              '/auth/check-phone',
              queryParameters: {'phone': '+27821234567'},
            )).called(1);
      });
    });

    group('completeRegistration', () {
      test('calls POST /auth/complete-registration with backend format', () async {
        when(() => mockDio.post(
              '/auth/complete-registration',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'memberId': 'user_123',
                'accessToken': 'access_abc',
                'refreshToken': 'refresh_xyz',
                'expiresIn': 3600,
              },
              statusCode: 201,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.completeRegistration(
          const BackendRegistrationRequest(
            phone: '+27821234567',
            firstName: 'John',
            surname: 'Doe',
            pin: '1234',
            address: '42 Doreen Road, Northcliff',
            sectorId: 'sector_1',
            latitude: -26.135,
            longitude: 27.98,
          ),
        );

        expect(result.memberId, 'user_123');
        expect(result.accessToken, 'access_abc');
        expect(result.refreshToken, 'refresh_xyz');
        expect(result.expiresIn, 3600);
      });
    });

    group('login', () {
      test('calls POST /auth/login with credentials (backend format)', () async {
        when(() => mockDio.post(
              '/auth/login',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'memberId': 'user_123',
                'accessToken': 'access_abc',
                'refreshToken': 'refresh_xyz',
                'expiresIn': 3600,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.login(
          const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
        );

        expect(result.memberId, 'user_123');
        expect(result.accessToken, 'access_abc');
        expect(result.refreshToken, 'refresh_xyz');
        verify(() => mockDio.post(
              '/auth/login',
              data: {'phone': '+27821234567', 'pin': '1234'},
            )).called(1);
      });
    });

    group('getMe', () {
      test('calls GET /members/me and returns profile', () async {
        when(() => mockDio.get('/members/me')).thenAnswer((_) async => Response(
              data: {
                'id': 'user_123',
                'firstName': 'John',
                'surname': 'Doe',
                'phoneNumber': '+27821234567',
                'address': '42 Doreen Road, Northcliff',
                'registrationLocation': {'latitude': -26.135, 'longitude': 27.98},
                'sectorId': 'sector_1',
                'status': 'ACTIVE',
                'createdAt': '2024-01-01T00:00:00Z',
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.getMe();

        expect(result.id, 'user_123');
        expect(result.firstName, 'John');
        expect(result.sectorId, 'sector_1');
      });
    });

    group('getSector', () {
      test('calls GET /sectors/{id} and returns sector info', () async {
        when(() => mockDio.get('/sectors/sector_1')).thenAnswer((_) async => Response(
              data: {
                'id': 'sector_1',
                'name': 'Northcliff',
                'center': {'latitude': -26.135, 'longitude': 27.98},
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await authApi.getSector('sector_1');

        expect(result.id, 'sector_1');
        expect(result.name, 'Northcliff');
        expect(result.center.latitude, -26.135);
      });
    });

    group('refreshToken', () {
      test('calls POST /auth/refresh with refresh token', () async {
        when(() => mockDio.post(
              '/auth/refresh',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'memberId': 'user_123',
                'accessToken': 'new_access_token',
                'refreshToken': 'new_refresh_token',
                'expiresIn': 3600,
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
