import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/message.dart';
import '../../../shared/providers/dio_provider.dart';
import '../../../shared/utils/result.dart';
import '../data/messages_api.dart';
import '../data/messages_repository.dart';

part 'messages_providers.g.dart';

// =============================================================================
// Infrastructure Providers
// =============================================================================

/// Provides MessagesApi
/// keepAlive: true to prevent disposal/recreation cycles
@Riverpod(keepAlive: true)
MessagesApi messagesApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return MessagesApi(dio);
}

/// Provides MessagesRepository
/// keepAlive: true to prevent disposal/recreation cycles
@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) {
  final api = ref.watch(messagesApiProvider);
  return MessagesRepository(api);
}

// =============================================================================
// Filter State
// =============================================================================

/// Filter parameters for messages
class MessagesFilter {
  final String? status;
  final String? type;
  final int page;
  final int size;

  const MessagesFilter({this.status, this.type, this.page = 1, this.size = 20});

  MessagesFilter copyWith({
    String? status,
    String? type,
    int? page,
    int? size,
    bool clearStatus = false,
    bool clearType = false,
  }) {
    return MessagesFilter(
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesFilter &&
          status == other.status &&
          type == other.type &&
          page == other.page &&
          size == other.size;

  @override
  int get hashCode => Object.hash(status, type, page, size);
}

/// Current messages filter state
@Riverpod(keepAlive: true)
class MessagesFilterState extends _$MessagesFilterState {
  @override
  MessagesFilter build() => const MessagesFilter();

  void setStatusFilter(String? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void nextPage() {
    state = state.copyWith(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) {
      state = state.copyWith(page: state.page - 1);
    }
  }

  void resetPage() {
    state = state.copyWith(page: 1);
  }

  void clearFilters() {
    state = const MessagesFilter();
  }
}

// =============================================================================
// Data Providers
// =============================================================================

/// Manages messages list data
@Riverpod(keepAlive: true)
class MessagesNotifier extends _$MessagesNotifier {
  @override
  Future<MessageListResponse> build() async {
    // Listen to filter changes and refetch
    ref.listen(messagesFilterStateProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.type != next.type ||
          previous?.page != next.page) {
        _fetch();
      }
    });

    return _fetchInternal();
  }

  Future<void> _fetch() async {
    state = const AsyncLoading();
    try {
      final data = await _fetchInternal();
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<MessageListResponse> _fetchInternal() async {
    final repository = ref.read(messagesRepositoryProvider);
    final filter = ref.read(messagesFilterStateProvider);

    final result = await repository.getMessages(
      status: filter.status,
      type: filter.type,
      page: filter.page,
      size: filter.size,
    );

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    await _fetch();
  }
}

/// Fetches a single message by ID
@riverpod
Future<Message> messageDetail(Ref ref, String messageId) async {
  final repository = ref.watch(messagesRepositoryProvider);
  final result = await repository.getMessage(messageId);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// Provides unread message count for badge display
@Riverpod(keepAlive: true)
class UnreadCountNotifier extends _$UnreadCountNotifier {
  @override
  Future<int> build() async {
    final repository = ref.read(messagesRepositoryProvider);
    final result = await repository.getUnreadCount();

    return switch (result) {
      Success(:final data) => data,
      Failure() => 0, // Return 0 on error to avoid breaking UI
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(messagesRepositoryProvider);
      final result = await repository.getUnreadCount();
      state = AsyncData(switch (result) {
        Success(:final data) => data,
        Failure() => 0,
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Decrement count when a message is read
  void decrementCount() {
    state.whenData((count) {
      if (count > 0) {
        state = AsyncData(count - 1);
      }
    });
  }
}

// =============================================================================
// Message Actions
// =============================================================================

/// State for message actions
sealed class MessageActionState {
  const MessageActionState();
}

class MessageActionStateIdle extends MessageActionState {
  const MessageActionStateIdle();
}

class MessageActionStateLoading extends MessageActionState {
  const MessageActionStateLoading();
}

class MessageActionStateSuccess extends MessageActionState {
  final Message message;
  const MessageActionStateSuccess(this.message);
}

class MessageActionStateError extends MessageActionState {
  final String message;
  const MessageActionStateError(this.message);
}

/// Manages message actions (mark as read, perform action)
@Riverpod(keepAlive: true)
class MessageActionNotifier extends _$MessageActionNotifier {
  @override
  MessageActionState build() => const MessageActionStateIdle();

  /// Mark a message as read
  Future<Result<Message>> markAsRead(String messageId) async {
    state = const MessageActionStateLoading();

    final repository = ref.read(messagesRepositoryProvider);
    final result = await repository.markAsRead(messageId);

    if (ref.mounted) {
      state = switch (result) {
        Success(:final data) => MessageActionStateSuccess(data),
        Failure(:final error) => MessageActionStateError(error.displayMessage),
      };

      if (result.isSuccess) {
        ref.read(unreadCountProvider.notifier).decrementCount();
        ref.invalidate(messageDetailProvider(messageId));
      }
    }

    return result;
  }

  /// Perform an action on a message
  Future<Result<Message>> performAction(
    String messageId,
    String action, {
    String? note,
  }) async {
    state = const MessageActionStateLoading();

    final repository = ref.read(messagesRepositoryProvider);
    final result = await repository.performAction(
      messageId,
      action,
      note: note,
    );

    if (ref.mounted) {
      state = switch (result) {
        Success(:final data) => MessageActionStateSuccess(data),
        Failure(:final error) => MessageActionStateError(error.displayMessage),
      };

      if (result.isSuccess) {
        // Refresh messages list and detail
        ref.invalidate(messagesProvider);
        ref.invalidate(messageDetailProvider(messageId));
        ref.read(unreadCountProvider.notifier).refresh();
      }
    }

    return result;
  }

  void reset() {
    state = const MessageActionStateIdle();
  }
}
