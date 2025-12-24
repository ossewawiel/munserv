import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/otp_request.dart';

void main() {
  group('OtpRequest', () {
    test('can be created with phone number', () {
      const request = OtpRequest(phoneNumber: '+27821234567');

      expect(request.phoneNumber, '+27821234567');
    });

    test('toJson serializes correctly', () {
      const request = OtpRequest(phoneNumber: '+27821234567');

      expect(request.toJson(), {'phoneNumber': '+27821234567'});
    });

    test('fromJson deserializes correctly', () {
      final request = OtpRequest.fromJson({'phoneNumber': '+27821234567'});

      expect(request.phoneNumber, '+27821234567');
    });

    test('equality works correctly', () {
      const request1 = OtpRequest(phoneNumber: '+27821234567');
      const request2 = OtpRequest(phoneNumber: '+27821234567');
      const request3 = OtpRequest(phoneNumber: '+27829999999');

      expect(request1, request2);
      expect(request1, isNot(request3));
    });
  });

  group('OtpRequestResponse', () {
    test('can be created with message and expiry', () {
      const response = OtpRequestResponse(
        message: 'OTP sent',
        expiresInSeconds: 300,
      );

      expect(response.message, 'OTP sent');
      expect(response.expiresInSeconds, 300);
    });

    test('toJson serializes correctly', () {
      const response = OtpRequestResponse(
        message: 'OTP sent',
        expiresInSeconds: 300,
      );

      expect(response.toJson(), {
        'message': 'OTP sent',
        'expiresInSeconds': 300,
      });
    });

    test('fromJson deserializes correctly', () {
      final response = OtpRequestResponse.fromJson({
        'message': 'OTP sent',
        'expiresInSeconds': 300,
      });

      expect(response.message, 'OTP sent');
      expect(response.expiresInSeconds, 300);
    });

    test('equality works correctly', () {
      const response1 = OtpRequestResponse(
        message: 'OTP sent',
        expiresInSeconds: 300,
      );
      const response2 = OtpRequestResponse(
        message: 'OTP sent',
        expiresInSeconds: 300,
      );
      const response3 = OtpRequestResponse(
        message: 'OTP sent',
        expiresInSeconds: 600,
      );

      expect(response1, response2);
      expect(response1, isNot(response3));
    });
  });
}
