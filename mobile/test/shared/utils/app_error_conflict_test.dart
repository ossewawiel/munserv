import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/utils/app_error.dart';

void main() {
  group('AppError.fromDio 409 Conflict handling', () {
    test(
      'creates ConflictError from 409 response with nested error format',
      () {
        // Format: {error: {code: 'x', message: 'y'}}
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
        final conflictError = error as ConflictError;
        expect(conflictError.errorCode, 'phone_registered');
        expect(
          conflictError.displayMessage,
          'Phone number is already registered',
        );
      },
    );

    test('creates ConflictError from 409 response with flat error format', () {
      // Format: {error: 'x', message: 'y'} - actual backend format
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          data: {
            'error': 'phone_registered',
            'message': 'Phone number is already registered',
          },
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      );

      final error = AppError.fromDio(dioException);

      expect(error, isA<ConflictError>());
      final conflictError = error as ConflictError;
      expect(conflictError.errorCode, 'phone_registered');
      expect(
        conflictError.displayMessage,
        'Phone number is already registered',
      );
    });

    test('creates ConflictError from 409 without error code', () {
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          data: {
            'error': {'message': 'Conflict occurred'},
          },
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      );

      final error = AppError.fromDio(dioException);

      expect(error, isA<ConflictError>());
      final conflictError = error as ConflictError;
      expect(conflictError.errorCode, isNull);
      expect(conflictError.displayMessage, 'Conflict occurred');
    });

    test('creates ConflictError from 409 with string data', () {
      final dioException = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 409,
          data: 'Conflict',
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      );

      final error = AppError.fromDio(dioException);

      // When response data is a string, we can't extract message/code
      // so we use the default message
      expect(error, isA<ConflictError>());
      final conflictError = error as ConflictError;
      expect(conflictError.errorCode, isNull);
      expect(conflictError.displayMessage, 'An error occurred');
    });
  });

  group('AppError.isPhoneRegistered', () {
    test('returns true for conflict with phone_registered code', () {
      const error = AppError.conflict(
        message: 'Phone number is already registered',
        errorCode: 'phone_registered',
      );

      expect(error.isPhoneRegistered, true);
    });

    test('returns false for conflict with different code', () {
      const error = AppError.conflict(
        message: 'Some conflict',
        errorCode: 'other_error',
      );

      expect(error.isPhoneRegistered, false);
    });

    test('returns false for conflict with null code', () {
      const error = AppError.conflict(
        message: 'Some conflict',
        errorCode: null,
      );

      expect(error.isPhoneRegistered, false);
    });

    test('returns false for non-conflict errors', () {
      const networkError = AppError.network(message: 'Network error');
      const validationError = AppError.validation(message: 'Invalid input');
      const unauthorizedError = AppError.unauthorized(message: 'Unauthorized');

      expect(networkError.isPhoneRegistered, false);
      expect(validationError.isPhoneRegistered, false);
      expect(unauthorizedError.isPhoneRegistered, false);
    });
  });
}
