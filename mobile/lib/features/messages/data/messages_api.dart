import 'package:dio/dio.dart';

import '../../../shared/models/message.dart';

/// API client for message endpoints.
/// All endpoints require Authorization header (handled by Dio interceptor).
class MessagesApi {
  final Dio _dio;

  MessagesApi(this._dio);

  /// List messages for current user.
  /// GET /messages?status={status}&type={type}&page={n}&size={n}
  Future<MessageListResponse> getMessages({
    String? status,
    String? type,
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/messages',
      queryParameters: {
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        'page': page,
        'size': size,
      },
    );
    return MessageListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get message detail by ID.
  /// GET /messages/{id}
  Future<Message> getMessage(String id) async {
    final response = await _dio.get('/messages/$id');
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mark message as read.
  /// PATCH /messages/{id}/read
  Future<Message> markAsRead(String id) async {
    final response = await _dio.patch('/messages/$id/read');
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  /// Perform action on message (accept, decline, approve, etc.).
  /// POST /messages/{id}/action
  Future<Message> performAction(String id, MessageActionRequest action) async {
    final response = await _dio.post(
      '/messages/$id/action',
      data: action.toJson(),
    );
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get unread message count.
  /// Fetches minimal data to get unread count.
  Future<int> getUnreadCount() async {
    final response = await _dio.get(
      '/messages',
      queryParameters: {'status': 'unread', 'size': 1},
    );
    final data = MessageListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    return data.unreadCount;
  }
}
