import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';

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
    group('getMe', () {
      test('calls GET /members/me and returns profile', () async {
        when(() => mockDio.get('/members/me')).thenAnswer(
          (_) async => Response(
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
          ),
        );

        final result = await authApi.getMe();

        expect(result.id, 'user_123');
        expect(result.firstName, 'John');
        expect(result.sectorId, 'sector_1');
      });
    });

    group('getSector', () {
      test('calls GET /sectors/{id} and returns sector info', () async {
        when(() => mockDio.get('/sectors/sector_1')).thenAnswer(
          (_) async => Response(
            data: {
              'id': 'sector_1',
              'name': 'Northcliff',
              'center': {'latitude': -26.135, 'longitude': 27.98},
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await authApi.getSector('sector_1');

        expect(result.id, 'sector_1');
        expect(result.name, 'Northcliff');
        expect(result.center.latitude, -26.135);
      });
    });

    group('refreshToken', () {
      test('calls POST /auth/refresh with refresh token', () async {
        when(
          () => mockDio.post('/auth/refresh', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'memberId': 'user_123',
              'accessToken': 'new_access_token',
              'refreshToken': 'new_refresh_token',
              'expiresIn': 3600,
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await authApi.refreshToken('old_refresh_token');

        expect(result.accessToken, 'new_access_token');
        expect(result.refreshToken, 'new_refresh_token');
        verify(
          () => mockDio.post(
            '/auth/refresh',
            data: {'refreshToken': 'old_refresh_token'},
          ),
        ).called(1);
      });
    });

    group('loginWithEmail', () {
      test('calls POST /auth/member/login with email and password', () async {
        when(
          () => mockDio.post('/auth/member/login', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'memberId': 'user_123',
              'accessToken': 'access_abc',
              'refreshToken': 'refresh_xyz',
              'expiresIn': 900,
              'mustChangePassword': true,
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await authApi.loginWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.memberId, 'user_123');
        expect(result.accessToken, 'access_abc');
        expect(result.refreshToken, 'refresh_xyz');
        expect(result.expiresIn, 900);
        expect(result.mustChangePassword, true);
        verify(
          () => mockDio.post(
            '/auth/member/login',
            data: {'email': 'test@example.com', 'password': 'password123'},
          ),
        ).called(1);
      });

      test('returns mustChangePassword as false for existing users', () async {
        when(
          () => mockDio.post('/auth/member/login', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'memberId': 'user_456',
              'accessToken': 'access_xyz',
              'refreshToken': 'refresh_abc',
              'expiresIn': 900,
              'mustChangePassword': false,
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await authApi.loginWithEmail(
          email: 'existing@example.com',
          password: 'existing_password',
        );

        expect(result.mustChangePassword, false);
      });
    });

    group('changePassword', () {
      test(
        'calls POST /auth/change-password with current and new password',
        () async {
          when(
            () =>
                mockDio.post('/auth/change-password', data: any(named: 'data')),
          ).thenAnswer(
            (_) async => Response(
              data: {'message': 'Password changed successfully'},
              statusCode: 200,
              requestOptions: RequestOptions(),
            ),
          );

          await authApi.changePassword(
            currentPassword: 'old_password',
            newPassword: 'New_Password123',
          );

          verify(
            () => mockDio.post(
              '/auth/change-password',
              data: {
                'currentPassword': 'old_password',
                'newPassword': 'New_Password123',
              },
            ),
          ).called(1);
        },
      );
    });
  });
}
