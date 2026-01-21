import 'package:dio/dio.dart';

import '../../../shared/models/ground_admin.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import 'ground_admin_api.dart';

/// Repository for Ground Admin operations.
/// Wraps GroundAdminApi and returns Result types for error handling.
class GroundAdminRepository {
  final GroundAdminApi _api;

  GroundAdminRepository(this._api);

  /// Get current member's Ground Admin info.
  /// Returns null wrapped in success if not a Ground Admin.
  Future<Result<GroundAdminInfo?>> getMyGroundAdminInfo() async {
    try {
      final response = await _api.getMyGroundAdminInfo();
      return Result.success(response);
    } on DioException catch (e) {
      // 404 means not a Ground Admin, which is a valid state
      if (e.response?.statusCode == 404) {
        return const Result.success(null);
      }
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Apply to become a Ground Admin.
  Future<Result<GroundAdminApplication>> apply() async {
    try {
      final response = await _api.apply();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Accept Ground Admin invitation.
  Future<Result<GroundAdminActionResponse>> acceptInvitation(
    String applicationId,
  ) async {
    try {
      final response = await _api.acceptInvitation(applicationId);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Decline Ground Admin invitation.
  Future<Result<void>> declineInvitation(
    String applicationId, {
    String? reason,
  }) async {
    try {
      await _api.declineInvitation(applicationId, reason: reason);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Request to step down from Ground Admin role.
  Future<Result<void>> stepDown({String? reason}) async {
    try {
      await _api.stepDown(reason: reason);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }
}
