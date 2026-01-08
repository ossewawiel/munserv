import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/utils/app_error.dart';

void main() {
  group('PhoneEntryPage 409 phone_registered handling', () {
    test('AppError.conflict should capture error code from 409 response', () {
      // Test that AppError can be created from a 409 response with error code
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          data: {
            'error': {
              'code': 'phone_registered',
              'message': 'Phone number is already registered',
            },
          },
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      );

      final error = AppError.fromDio(dioException);

      expect(error, isA<ConflictError>());
      expect((error as ConflictError).errorCode, 'phone_registered');
      expect(error.displayMessage, 'Phone number is already registered');
    });

    test('AppError.isPhoneRegistered returns true for phone_registered code',
        () {
      const error = AppError.conflict(
        message: 'Phone number is already registered',
        errorCode: 'phone_registered',
      );

      expect(error.isPhoneRegistered, true);
    });

    test('AppError.isPhoneRegistered returns false for other conflict codes',
        () {
      const error = AppError.conflict(
        message: 'Some other conflict',
        errorCode: 'other_conflict',
      );

      expect(error.isPhoneRegistered, false);
    });

    test('AppError.isPhoneRegistered returns false for non-conflict errors',
        () {
      const networkError = AppError.network(message: 'Network error');
      const validationError = AppError.validation(message: 'Invalid input');

      expect(networkError.isPhoneRegistered, false);
      expect(validationError.isPhoneRegistered, false);
    });
  });
}
