import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const AppError._();

  const factory AppError.network({required String message, int? statusCode}) =
      NetworkError;

  const factory AppError.validation({required String message, String? field}) =
      ValidationError;

  const factory AppError.unauthorized({String? message}) = UnauthorizedError;

  const factory AppError.notFound({String? message}) = NotFoundError;

  const factory AppError.server({required String message}) = ServerError;

  const factory AppError.conflict({
    required String message,
    String? errorCode,
  }) = ConflictError;

  const factory AppError.unknown({required String message}) = UnknownError;

  factory AppError.fromDio(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'An error occurred';
    String? errorCode;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        // Nested format: {error: {code: 'x', message: 'y'}}
        message = error['message'] as String? ?? message;
        errorCode = error['code'] as String?;
      } else if (error is String) {
        // Flat format: {error: 'x', message: 'y'}
        errorCode = error;
        message = data['message'] as String? ?? message;
      }
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => AppError.network(
        message: 'Connection timeout',
        statusCode: statusCode,
      ),
      DioExceptionType.connectionError => const AppError.network(
        message: 'No internet connection',
      ),
      DioExceptionType.badResponse => switch (statusCode) {
        400 => AppError.validation(message: message),
        401 => AppError.unauthorized(message: message),
        403 => AppError.unauthorized(message: 'Access denied'),
        404 => AppError.notFound(message: message),
        409 => AppError.conflict(message: message, errorCode: errorCode),
        final code when code != null && code >= 500 => AppError.server(
          message: message,
        ),
        _ => AppError.network(message: message, statusCode: statusCode),
      },
      _ => AppError.unknown(message: e.message ?? 'Unknown error'),
    };
  }

  String get displayMessage => switch (this) {
    NetworkError(:final message) => message,
    ValidationError(:final message) => message,
    UnauthorizedError(:final message) => message ?? 'Please log in again',
    NotFoundError(:final message) => message ?? 'Not found',
    ServerError(:final message) => message,
    ConflictError(:final message) => message,
    UnknownError(:final message) => message,
  };

  /// Returns true if this error indicates phone is already registered
  bool get isPhoneRegistered => switch (this) {
    ConflictError(:final errorCode) => errorCode == 'phone_registered',
    _ => false,
  };
}
