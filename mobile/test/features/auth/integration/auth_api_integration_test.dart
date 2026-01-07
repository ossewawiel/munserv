/// Integration tests for Auth API against the Spring Boot backend.
///
/// Run with: flutter test test/features/auth/integration/
///
/// Prerequisites:
/// 1. Start backend: cd backend && ./gradlew bootRun
/// 2. Backend runs on http://localhost:8080/api/v1
@Tags(['integration'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/domain/backend_registration_request.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';

void main() {
  late Dio dio;
  late AuthApi authApi;

  setUpAll(() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    authApi = AuthApi(dio);
  });

  tearDownAll(() {
    dio.close();
  });

  group('Auth API Integration Tests', () {
    group('requestOtp', () {
      test('successfully requests OTP for valid phone number', () async {
        final response = await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27821234567'),
        );

        expect(response.message, isNotEmpty);
        expect(response.expiresInSeconds, greaterThan(0));
      });

      test('fails for invalid phone format', () async {
        expect(
          () => authApi.requestOtp(const OtpRequest(phoneNumber: 'invalid')),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('verifyOtp', () {
      test('successfully verifies OTP (returns void)', () async {
        // Request OTP first
        await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27821234567'),
        );

        // Backend verifyOtp returns void - success is indicated by no exception
        await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
        );

        // If we get here, OTP verification succeeded
        expect(true, isTrue);
      });

      test('can check if phone is registered after OTP verification', () async {
        // Request and verify OTP
        await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27821234567'),
        );
        await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
        );

        // Check phone registration status
        final checkResponse = await authApi.checkPhone('+27821234567');

        // This phone should be registered (test data)
        expect(checkResponse.isRegistered, isTrue);
      });

      test('returns not registered for new phone number', () async {
        final uniquePhone =
            '+2782${DateTime.now().millisecondsSinceEpoch % 10000000}';

        await authApi.requestOtp(OtpRequest(phoneNumber: uniquePhone));
        await authApi.verifyOtp(
            OtpVerifyRequest(phoneNumber: uniquePhone, otp: '123456'));

        final checkResponse = await authApi.checkPhone(uniquePhone);
        expect(checkResponse.isRegistered, isFalse);
      });

      test('fails for invalid OTP', () async {
        await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27821234567'),
        );

        expect(
          () => authApi.verifyOtp(
            const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '000000'),
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('completeRegistration', () {
      test('successfully registers new user', () async {
        // Use a unique phone number for each test run
        final uniquePhone =
            '+2782${DateTime.now().millisecondsSinceEpoch % 10000000}';

        // Request and verify OTP
        await authApi.requestOtp(OtpRequest(phoneNumber: uniquePhone));
        await authApi.verifyOtp(
            OtpVerifyRequest(phoneNumber: uniquePhone, otp: '123456'));

        // Complete registration with backend request format
        final response = await authApi.completeRegistration(
          BackendRegistrationRequest(
            phone: uniquePhone,
            firstName: 'Integration',
            surname: 'Test',
            pin: '5678',
            address: '123 Test Street, Northcliff',
            sectorId: 'sector_1',
            latitude: -26.135,
            longitude: 27.98,
          ),
        );

        // Backend returns flat response
        expect(response.accessToken, isNotEmpty);
        expect(response.refreshToken, isNotEmpty);
        expect(response.memberId, isNotEmpty);
      });

      test('fails with unverified phone', () async {
        final uniquePhone =
            '+2782${DateTime.now().millisecondsSinceEpoch % 10000000}';

        // Try to register without OTP verification
        expect(
          () => authApi.completeRegistration(
            BackendRegistrationRequest(
              phone: uniquePhone,
              firstName: 'Test',
              surname: 'User',
              pin: '1234',
              address: 'Test Address',
              sectorId: 'sector_1',
              latitude: -26.135,
              longitude: 27.98,
            ),
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('login', () {
      test('successfully logs in with valid credentials', () async {
        final response = await authApi.login(
          const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
        );

        // Backend returns flat response
        expect(response.accessToken, isNotEmpty);
        expect(response.refreshToken, isNotEmpty);
        expect(response.memberId, isNotEmpty);
      });

      test('fails with invalid PIN', () async {
        expect(
          () => authApi.login(
            const LoginRequest(phoneNumber: '+27821234567', pin: '0000'),
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('fails with unknown phone number', () async {
        expect(
          () => authApi.login(
            const LoginRequest(phoneNumber: '+27820000000', pin: '1234'),
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('refreshToken', () {
      test('successfully refreshes token', () async {
        // First login to get a refresh token
        final loginResponse = await authApi.login(
          const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
        );

        // Refresh it
        final newTokens = await authApi.refreshToken(
          loginResponse.refreshToken,
        );

        // Backend returns flat response
        expect(newTokens.accessToken, isNotEmpty);
        expect(newTokens.refreshToken, isNotEmpty);
      });
    });

    group('getMe', () {
      test('returns member profile with valid token', () async {
        // Login to get token
        final loginResponse = await authApi.login(
          const LoginRequest(phoneNumber: '+27821234567', pin: '1234'),
        );

        // Create authenticated Dio instance
        final authedDio = Dio(BaseOptions(
          baseUrl: 'http://localhost:8080/api/v1',
          headers: {'Authorization': 'Bearer ${loginResponse.accessToken}'},
        ));
        final authedApi = AuthApi(authedDio);

        // Get profile
        final profile = await authedApi.getMe();

        expect(profile.id, isNotEmpty);
        expect(profile.phoneNumber, '+27821234567');

        authedDio.close();
      });
    });
  });
}
