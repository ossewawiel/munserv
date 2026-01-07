import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/data/auth_repository.dart';
import 'package:munserv_mobile/features/auth/data/secure_storage.dart';
import 'package:munserv_mobile/features/auth/domain/backend_login_response.dart';
import 'package:munserv_mobile/features/auth/domain/backend_registration_request.dart';
import 'package:munserv_mobile/features/auth/domain/check_phone_response.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/member_profile_response.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';
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

const testAuthResponse = AuthResponse(
  tokens: testTokens,
  profile: testProfile,
);

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
    registerFallbackValue(const OtpRequest(phoneNumber: '+27821234567'));
    registerFallbackValue(
      const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
    );
    registerFallbackValue(const BackendRegistrationRequest(
      phone: '+27821234567',
      firstName: 'John',
      surname: 'Doe',
      pin: '1234',
      address: '42 Doreen Road',
      sectorId: 'sector_1',
      latitude: -26.135,
      longitude: 27.98,
    ));
    registerFallbackValue(
      const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
    );
    registerFallbackValue(testTokens);
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
      test('returns Success with NewUser when phone not registered', () async {
        // Backend flow: verifyOtp() returns void, then checkPhone() is called
        when(() => mockApi.verifyOtp(any())).thenAnswer((_) async {});
        when(() => mockApi.checkPhone(any())).thenAnswer(
          (_) async => const CheckPhoneResponse(isRegistered: false),
        );

        final result = await repository.verifyOtp('+27821234567', '123456');

        expect(result.isSuccess, true);
        expect(result.dataOrNull, isA<OtpVerifyResultNewUser>());
        expect(result.dataOrNull?.isNewUser, true);
      });

      test('returns Success with ExistingUser when phone is registered',
          () async {
        when(() => mockApi.verifyOtp(any())).thenAnswer((_) async {});
        when(() => mockApi.checkPhone(any())).thenAnswer(
          (_) async => const CheckPhoneResponse(isRegistered: true),
        );

        final result = await repository.verifyOtp('+27821234567', '123456');

        expect(result.isSuccess, true);
        expect(result.dataOrNull, isA<OtpVerifyResultExistingUser>());
        expect(result.dataOrNull?.isExistingUser, true);
        // Backend flow returns null tokens/profile - user must login with PIN
        final existing = result.dataOrNull as OtpVerifyResultExistingUser;
        expect(existing.tokens, isNull);
        expect(existing.profile, isNull);
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
        // Backend flow: register -> save tokens -> getMe -> getSector
        when(() => mockApi.completeRegistration(any()))
            .thenAnswer((_) async => testBackendLoginResponse);
        when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
        when(() => mockApi.getMe())
            .thenAnswer((_) async => testMemberProfileResponse);
        when(() => mockApi.getSector(any()))
            .thenAnswer((_) async => testSectorInfo);

        final result = await repository.completeRegistration(
          phoneNumber: '+27821234567',
          firstName: 'John',
          surname: 'Doe',
          pin: '1234',
          location: const GeoPoint(latitude: -26.135, longitude: 27.98),
          address: '42 Doreen Road',
          sectorId: 'sector_1',
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.tokens.accessToken, 'access_abc');
        expect(result.dataOrNull?.profile.member.firstName, 'John');

        // Verify tokens were saved
        verify(() => mockStorage.saveTokens(any())).called(1);
      });

      test('returns Failure on registration error', () async {
        when(() => mockApi.completeRegistration(any())).thenThrow(
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
          phoneNumber: '+27821234567',
          firstName: 'John',
          surname: 'Doe',
          pin: '1234',
          location: const GeoPoint(latitude: -26.135, longitude: 27.98),
          address: '42 Doreen Road',
          sectorId: 'sector_1',
        );

        expect(result.isFailure, true);
      });
    });

    group('login', () {
      test('returns Success with AuthResponse', () async {
        // Backend flow: login -> save tokens -> getMe -> getSector
        when(() => mockApi.login(any()))
            .thenAnswer((_) async => testBackendLoginResponse);
        when(() => mockStorage.saveTokens(any())).thenAnswer((_) async {});
        when(() => mockApi.getMe())
            .thenAnswer((_) async => testMemberProfileResponse);
        when(() => mockApi.getSector(any()))
            .thenAnswer((_) async => testSectorInfo);

        final result = await repository.login('+27821234567', '1234');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.tokens.accessToken, 'access_abc');
        expect(result.dataOrNull?.profile.member.id, 'user_123');

        // Verify tokens were saved
        verify(() => mockStorage.saveTokens(any())).called(1);
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
        const newBackendResponse = BackendLoginResponse(
          memberId: 'user_123',
          accessToken: 'new_access',
          refreshToken: 'new_refresh',
          expiresIn: 3600,
        );
        when(() => mockApi.refreshToken(any()))
            .thenAnswer((_) async => newBackendResponse);
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
