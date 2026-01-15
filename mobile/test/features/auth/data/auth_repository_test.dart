import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/auth_types.dart';
import 'package:munserv_mobile/features/auth/domain/backend_login_response.dart';
import 'package:munserv_mobile/features/auth/domain/member_login_response.dart';
import 'package:munserv_mobile/features/auth/domain/member_profile_response.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/utils/result.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Test data for auth responses
const testTokens = AuthTokens(
  accessToken: 'access_abc',
  refreshToken: 'refresh_xyz',
);

const testMemberProfile = MemberProfile(
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

const testSectorInfo = SectorInfo(
  id: 'sector_1',
  name: 'Northcliff',
  center: GeoPoint(latitude: -26.135, longitude: 27.98),
);

const testProfile = AuthProfile(
  member: testMemberProfile,
  sector: testSectorInfo,
);

const testAuthResponse = AuthResponse(tokens: testTokens, profile: testProfile);

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

const testBackendLoginResponse = BackendLoginResponse(
  memberId: 'user_123',
  accessToken: 'access_abc',
  refreshToken: 'refresh_xyz',
  expiresIn: 3600,
);

void main() {
  late MockAuthApi mockApi;
  late MockSecureStorageService mockStorage;
  late AuthRepository repository;

  setUp(() {
    mockApi = MockAuthApi();
    mockStorage = MockSecureStorageService();
    repository = AuthRepository(mockApi, mockStorage);
  });

  setUpAll(() {
    registerFallbackValue(testTokens);
  });

  group('AuthRepository', () {
    group('refreshToken', () {
      test('returns Success with new tokens', () async {
        const newBackendResponse = BackendLoginResponse(
          memberId: 'user_123',
          accessToken: 'new_access',
          refreshToken: 'new_refresh',
          expiresIn: 3600,
        );
        when(
          () => mockApi.refreshToken(any()),
        ).thenAnswer((_) async => newBackendResponse);
        when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});

        final result = await repository.refreshToken('old_refresh');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.accessToken, 'new_access');

        // Verify new tokens were saved
        verify(() => mockStorage.saveTokens(any())).called(1);
      });

      test('returns Failure on expired refresh token', () async {
        when(() => mockApi.refreshToken(any())).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              data: {
                'error': {'message': 'Token expired'},
              },
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.refreshToken('expired_token');

        expect(result.isFailure, true);
      });
    });

    group('loginWithEmail', () {
      const testMemberLoginResponse = MemberLoginResponse(
        memberId: 'user_123',
        accessToken: 'access_abc',
        refreshToken: 'refresh_xyz',
        expiresIn: 900,
        mustChangePassword: true,
      );

      test('returns Success with MemberLoginResponse', () async {
        when(
          () => mockApi.loginWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => testMemberLoginResponse);

        final result = await repository.loginWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.memberId, 'user_123');
        expect(result.dataOrNull?.mustChangePassword, true);
        expect(result.dataOrNull?.accessToken, 'access_abc');
      });

      test('returns Failure on invalid credentials', () async {
        when(
          () => mockApi.loginWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              data: {
                'error': {'message': 'Invalid credentials'},
              },
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.loginWithEmail(
          email: 'wrong@example.com',
          password: 'wrong_password',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Invalid credentials');
      });

      test('returns Failure on account pending approval (403)', () async {
        when(
          () => mockApi.loginWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 403,
              data: {
                'error': {'message': 'Account pending approval'},
              },
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.loginWithEmail(
          email: 'pending@example.com',
          password: 'password',
        );

        expect(result.isFailure, true);
        // 403 returns hardcoded 'Access denied' from AppError.fromDio
        expect(result.errorOrNull?.displayMessage, 'Access denied');
      });
    });

    group('changePassword', () {
      test('returns Success when password changed', () async {
        when(
          () => mockApi.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.changePassword(
          currentPassword: 'old_password',
          newPassword: 'New_Password123',
        );

        expect(result.isSuccess, true);
      });

      test('returns Failure on wrong current password', () async {
        when(
          () => mockApi.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              data: {
                'error': {'message': 'Wrong current password'},
              },
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.changePassword(
          currentPassword: 'wrong_password',
          newPassword: 'New_Password123',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Wrong current password');
      });

      test('returns Failure on password validation error', () async {
        when(
          () => mockApi.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 400,
              data: {
                'error': {'message': 'Password too weak'},
              },
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.changePassword(
          currentPassword: 'old_password',
          newPassword: 'weak',
        );

        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Password too weak');
      });
    });

    group('getMe', () {
      test('returns Success with MemberProfileResponse', () async {
        when(
          () => mockApi.getMe(),
        ).thenAnswer((_) async => testMemberProfileResponse);

        final result = await repository.getMe();

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'user_123');
        expect(result.dataOrNull?.firstName, 'John');
      });

      test('returns Failure on unauthorized', () async {
        when(() => mockApi.getMe()).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              data: {
                'error': {'message': 'Unauthorized'},
              },
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.getMe();

        expect(result.isFailure, true);
      });
    });
  });
}
