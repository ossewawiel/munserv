/// Integration tests for Auth API against the mock server.
///
/// Run with: flutter test test/features/auth/integration/
///
/// Prerequisites:
/// 1. Start mock API: cd infrastructure/mock-api && npm start
/// 2. Mock API runs on http://localhost:3001/api/v1
@Tags(['integration'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/data/auth_api.dart';
import 'package:munserv_mobile/features/auth/domain/login_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';
import 'package:munserv_mobile/features/auth/domain/otp_verify_result.dart';
import 'package:munserv_mobile/features/auth/domain/registration_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

void main() {
  late Dio dio;
  late AuthApi authApi;

  setUpAll(() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3001/api/v1',
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

        expect(response.message, 'OTP sent');
        expect(response.expiresInSeconds, 300);
      });

      test('fails for invalid phone format', () async {
        expect(
          () => authApi.requestOtp(const OtpRequest(phoneNumber: 'invalid')),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('verifyOtp', () {
      test('returns newUser for unregistered phone number', () async {
        // First request OTP for a new number
        await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27829999999'),
        );

        // Then verify with correct OTP
        final result = await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27829999999', otp: '123456'),
        );

        expect(result.isNewUser, true);
        expect(result, isA<OtpVerifyResultNewUser>());
        expect((result as OtpVerifyResultNewUser).tempToken, isNotEmpty);
      });

      test('returns existingUser for registered phone number', () async {
        // Request OTP for existing test member
        await authApi.requestOtp(
          const OtpRequest(phoneNumber: '+27821234567'),
        );

        // Verify OTP
        final result = await authApi.verifyOtp(
          const OtpVerifyRequest(phoneNumber: '+27821234567', otp: '123456'),
        );

        expect(result.isExistingUser, true);
        expect(result, isA<OtpVerifyResultExistingUser>());
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
        final uniquePhone = '+2782${DateTime.now().millisecondsSinceEpoch % 10000000}';

        // First get a temp token
        await authApi.requestOtp(
          OtpRequest(phoneNumber: uniquePhone),
        );
        final verifyResult = await authApi.verifyOtp(
          OtpVerifyRequest(phoneNumber: uniquePhone, otp: '123456'),
        );

        expect(verifyResult.isNewUser, true);
        final tempToken = (verifyResult as OtpVerifyResultNewUser).tempToken;

        // Complete registration
        final response = await authApi.completeRegistration(
          tempToken: tempToken,
          request: const RegistrationRequest(
            firstName: 'Integration',
            surname: 'Test',
            pin: '5678',
            location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
            address: '123 Test Street, Northcliff',
          ),
        );

        expect(response.tokens.accessToken, isNotEmpty);
        expect(response.tokens.refreshToken, isNotEmpty);
        expect(response.profile.member.firstName, 'Integration');
        expect(response.profile.member.surname, 'Test');
      });

      test('fails with invalid temp token', () async {
        expect(
          () => authApi.completeRegistration(
            tempToken: 'invalid-token',
            request: const RegistrationRequest(
              firstName: 'Test',
              surname: 'User',
              pin: '1234',
              location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
              address: 'Test Address',
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

        // Backend returns flat response (not nested tokens/profile)
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

        // Refresh it (backend returns flat response)
        final newTokens = await authApi.refreshToken(
          loginResponse.refreshToken,
        );

        expect(newTokens.accessToken, isNotEmpty);
        expect(newTokens.refreshToken, isNotEmpty);
      });
    });
  });
}
