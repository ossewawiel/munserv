import 'package:dio/dio.dart';

import '../../../shared/models/message.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import 'messages_api.dart';

/// Repository for message operations.
/// Wraps MessagesApi and returns Result types for error handling.
class MessagesRepository {
  final MessagesApi _api;

  MessagesRepository(this._api);

  /// Get paginated list of messages with optional filters.
  Future<Result<MessageListResponse>> getMessages({
    String? status,
    String? type,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _api.getMessages(
        status: status,
        type: type,
        page: page,
        size: size,
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get message by ID.
  Future<Result<Message>> getMessage(String id) async {
    try {
      final response = await _api.getMessage(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Mark message as read.
  Future<Result<Message>> markAsRead(String id) async {
    try {
      final response = await _api.markAsRead(id);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Perform action on message.
  Future<Result<Message>> performAction(
    String id,
    String action, {
    String? note,
  }) async {
    try {
      final request = MessageActionRequest(action: action, note: note);
      final response = await _api.performAction(id, request);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get unread message count.
  Future<Result<int>> getUnreadCount() async {
    try {
      final count = await _api.getUnreadCount();
      return Result.success(count);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }
}
