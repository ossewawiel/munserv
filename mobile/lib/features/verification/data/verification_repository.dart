import 'dart:io';

import 'package:dio/dio.dart';

import '../../../shared/models/notification_settings.dart';
import '../../../shared/models/verification.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import 'verification_api.dart';

/// Repository for verification operations.
/// Wraps VerificationApi and returns Result types for error handling.
class VerificationRepository {
  final VerificationApi _api;

  VerificationRepository(this._api);

  /// Get pending verifications for current Ground Admin.
  Future<Result<List<PendingVerification>>> getPendingVerifications() async {
    try {
      final response = await _api.getPendingVerifications();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Submit verification result.
  Future<Result<IssueVerification>> submitVerification({
    required String issueId,
    required String verificationId,
    required String result,
    String? reason,
    String? note,
    File? photo,
  }) async {
    try {
      final response = await _api.submitVerification(
        issueId: issueId,
        verificationId: verificationId,
        result: result,
        reason: reason,
        note: note,
        photo: photo,
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get verification history for an issue.
  Future<Result<List<IssueVerification>>> getVerificationHistory(
    String issueId,
  ) async {
    try {
      final response = await _api.getVerificationHistory(issueId);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get notification settings.
  Future<Result<NotificationSettings>> getNotificationSettings() async {
    try {
      final response = await _api.getNotificationSettings();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Update notification settings.
  Future<Result<NotificationSettings>> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    try {
      final response = await _api.updateNotificationSettings(settings);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }
}
