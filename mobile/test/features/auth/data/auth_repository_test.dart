import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';
import 'package:munserv_mobile/features/auth/domain/registration_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/utils/result.dart';

class MockAuthApi extends Mock implements AuthApi {}

/// Test data for auth responses
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
    address: '42 Doreen Road, Northcliff',
    registrationLocation: GeoPoint(latitude: -26.135, longitude: 27.98),
    sectorId: 'sector_1',
    status: 'active',
    createdAt: '2024-01-01T00:00:00Z',
  ),
  sector: SectorInfo(
    id: 'sector_1',
    name: 'Northcliff',
    center: GeoPoint(latitude: -26.135, longitude: 27.98),
  ),
);

const testAuthResponse = AuthResponse(
  tokens: testTokens,
  profile: testProfile,
);

void main() {
  late MockAuthApi mockApi;
  late AuthRepository repository;

  setUp(() {
    mockApi = MockAuthApi();
    repository = AuthRepository(mockApi);
  });

  setUpAll(() {
    registerFallbackValue(const OtpRequest(phoneNumber: '+27821234567'));
    registerFallbackValue(
      const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
    );
    registerFallbackValue(const RegistrationRequest(
      firstName: 'John',
      surname: 'Doe',
      pin: '1234',
      location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
      address: '42 Doreen Road',
    ));
    registerFallbackValue(
      const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
    );
  });

  group('AuthRepository', () {
    group('requestOtp', () {
      test('returns Success with OtpRequestResponse on success', () async {
        when(() => mockApi.requestOtp(any())).thenAnswer(
          (_) async => const OtpRequestResponse(
            message: 'OTP sent',
            expiresInSeconds: 300,
          ),
        );

        final result = await repository.requestOtp('+27821234567');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.message, 'OTP sent');
        expect(result.dataOrNull?.expiresInSeconds, 300);
      });

      test('returns Failure on DioException', () async {
        when(() => mockApi.requestOtp(any())).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 400,
              data: {'error': {'message': 'Invalid phone number'}},
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.requestOtp('+27821234567');

        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Invalid phone number');
      });

      test('returns Failure on unknown exception', () async {
        when(() => mockApi.requestOtp(any())).thenThrow(Exception('Unknown'));

        final result = await repository.requestOtp('+27821234567');

        expect(result.isFailure, true);
      });
    });

    group('verifyOtp', () {
      test('returns Success with NewUser result', () async {
        when(() => mockApi.verifyOtp(any())).thenAnswer(
          (_) async => const OtpVerifyResult.newUser(tempToken: 'temp_abc'),
        );

        final result = await repository.verifyOtp('+27821234567', '123456');

        expect(result.isSuccess, true);
        expect(result.dataOrNull, isA<OtpVerifyResultNewUser>());
      });

      test('returns Success with ExistingUser result', () async {
        when(() => mockApi.verifyOtp(any())).thenAnswer(
          (_) async => const OtpVerifyResult.existingUser(
            tokens: testTokens,
            profile: testProfile,
          ),
        );

        final result = await repository.verifyOtp('+27821234567', '123456');

        expect(result.isSuccess, true);
        expect(result.dataOrNull, isA<OtpVerifyResultExistingUser>());
        final existing = result.dataOrNull as OtpVerifyResultExistingUser;
        expect(existing.tokens.accessToken, 'access_abc');
        expect(existing.profile.member.id, 'user_123');
      });

      test('returns Failure on invalid OTP', () async {
        when(() => mockApi.verifyOtp(any())).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 400,
              data: {'error': {'message': 'Invalid OTP'}},
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.verifyOtp('+27821234567', '000000');

        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Invalid OTP');
      });
    });

    group('completeRegistration', () {
      test('returns Success with AuthResponse', () async {
        when(() => mockApi.completeRegistration(
              tempToken: any(named: 'tempToken'),
              request: any(named: 'request'),
            )).thenAnswer((_) async => testAuthResponse);

        final result = await repository.completeRegistration(
          tempToken: 'temp_abc',
          firstName: 'John',
          surname: 'Doe',
          pin: '1234',
          location: const GeoPoint(latitude: -26.1350, longitude: 27.9800),
          address: '42 Doreen Road',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.tokens.accessToken, 'access_abc');
        expect(result.dataOrNull?.profile.member.firstName, 'John');
      });

      test('returns Failure on error', () async {
        when(() => mockApi.completeRegistration(
              tempToken: any(named: 'tempToken'),
              request: any(named: 'request'),
            )).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 400,
              data: {'error': {'message': 'Registration failed'}},
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.completeRegistration(
          tempToken: 'temp_abc',
          firstName: 'John',
          surname: 'Doe',
          pin: '1234',
          location: const GeoPoint(latitude: -26.1350, longitude: 27.9800),
          address: '42 Doreen Road',
        );

        expect(result.isFailure, true);
      });
    });

    group('login', () {
      test('returns Success with AuthResponse', () async {
        when(() => mockApi.login(any())).thenAnswer(
          (_) async => testAuthResponse,
        );

        final result = await repository.login('+27821234567', '1234');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.tokens.accessToken, 'access_abc');
        expect(result.dataOrNull?.profile.member.id, 'user_123');
      });

      test('returns Failure on invalid PIN', () async {
        when(() => mockApi.login(any())).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              data: {'error': {'message': 'Invalid PIN'}},
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.login('+27821234567', '0000');

        expect(result.isFailure, true);
        expect(result.errorOrNull?.displayMessage, 'Invalid PIN');
      });
    });

    group('refreshToken', () {
      test('returns Success with new tokens', () async {
        when(() => mockApi.refreshToken(any())).thenAnswer(
          (_) async => const AuthTokens(
            accessToken: 'new_access',
            refreshToken: 'new_refresh',
          ),
        );

        final result = await repository.refreshToken('old_refresh');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.accessToken, 'new_access');
      });

      test('returns Failure on expired refresh token', () async {
        when(() => mockApi.refreshToken(any())).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              data: {'error': {'message': 'Token expired'}},
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.refreshToken('expired_token');

        expect(result.isFailure, true);
      });
    });
  });
}
