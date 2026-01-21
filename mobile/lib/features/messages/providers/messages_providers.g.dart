// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides MessagesApi
/// keepAlive: true to prevent disposal/recreation cycles

@ProviderFor(messagesApi)
const messagesApiProvider = MessagesApiProvider._();

/// Provides MessagesApi
/// keepAlive: true to prevent disposal/recreation cycles

final class MessagesApiProvider
    extends $FunctionalProvider<MessagesApi, MessagesApi, MessagesApi>
    with $Provider<MessagesApi> {
  /// Provides MessagesApi
  /// keepAlive: true to prevent disposal/recreation cycles
  const MessagesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesApiHash();

  @$internal
  @override
  $ProviderElement<MessagesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessagesApi create(Ref ref) {
    return messagesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesApi>(value),
    );
  }
}

String _$messagesApiHash() => r'993eb1cfd288303e878d991f98e64480f914bf41';

/// Provides MessagesRepository
/// keepAlive: true to prevent disposal/recreation cycles

@ProviderFor(messagesRepository)
const messagesRepositoryProvider = MessagesRepositoryProvider._();

/// Provides MessagesRepository
/// keepAlive: true to prevent disposal/recreation cycles

final class MessagesRepositoryProvider
    extends
        $FunctionalProvider<
          MessagesRepository,
          MessagesRepository,
          MessagesRepository
        >
    with $Provider<MessagesRepository> {
  /// Provides MessagesRepository
  /// keepAlive: true to prevent disposal/recreation cycles
  const MessagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessagesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessagesRepository create(Ref ref) {
    return messagesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesRepository>(value),
    );
  }
}

String _$messagesRepositoryHash() =>
    r'1a0a9f56a4af2874042b44803537b5288e3678b7';

/// Current messages filter state

@ProviderFor(MessagesFilterState)
const messagesFilterStateProvider = MessagesFilterStateProvider._();

/// Current messages filter state
final class MessagesFilterStateProvider
    extends $NotifierProvider<MessagesFilterState, MessagesFilter> {
  /// Current messages filter state
  const MessagesFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesFilterStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesFilterStateHash();

  @$internal
  @override
  MessagesFilterState create() => MessagesFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesFilter>(value),
    );
  }
}

String _$messagesFilterStateHash() =>
    r'0f91b99939581f5df1808c3f2b989990fdecf178';

/// Current messages filter state

abstract class _$MessagesFilterState extends $Notifier<MessagesFilter> {
  MessagesFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MessagesFilter, MessagesFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MessagesFilter, MessagesFilter>,
              MessagesFilter,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Manages messages list data

@ProviderFor(MessagesNotifier)
const messagesProvider = MessagesNotifierProvider._();

/// Manages messages list data
final class MessagesNotifierProvider
    extends $AsyncNotifierProvider<MessagesNotifier, MessageListResponse> {
  /// Manages messages list data
  const MessagesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesNotifierHash();

  @$internal
  @override
  MessagesNotifier create() => MessagesNotifier();
}

String _$messagesNotifierHash() => r'3237a50dad79170ce5dfad80b61f13788b18389f';

/// Manages messages list data

abstract class _$MessagesNotifier extends $AsyncNotifier<MessageListResponse> {
  FutureOr<MessageListResponse> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<MessageListResponse>, MessageListResponse>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MessageListResponse>, MessageListResponse>,
              AsyncValue<MessageListResponse>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Fetches a single message by ID

@ProviderFor(messageDetail)
const messageDetailProvider = MessageDetailFamily._();

/// Fetches a single message by ID

final class MessageDetailProvider
    extends $FunctionalProvider<AsyncValue<Message>, Message, FutureOr<Message>>
    with $FutureModifier<Message>, $FutureProvider<Message> {
  /// Fetches a single message by ID
  const MessageDetailProvider._({
    required MessageDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageDetailHash();

  @override
  String toString() {
    return r'messageDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Message> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Message> create(Ref ref) {
    final argument = this.argument as String;
    return messageDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageDetailHash() => r'69447946ea16dca2ccf7188058b3d4349e3370d6';

/// Fetches a single message by ID

final class MessageDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Message>, String> {
  const MessageDetailFamily._()
    : super(
        retry: null,
        name: r'messageDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single message by ID

  MessageDetailProvider call(String messageId) =>
      MessageDetailProvider._(argument: messageId, from: this);

  @override
  String toString() => r'messageDetailProvider';
}

/// Provides unread message count for badge display

@ProviderFor(UnreadCountNotifier)
const unreadCountProvider = UnreadCountNotifierProvider._();

/// Provides unread message count for badge display
final class UnreadCountNotifierProvider
    extends $AsyncNotifierProvider<UnreadCountNotifier, int> {
  /// Provides unread message count for badge display
  const UnreadCountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadCountNotifierHash();

  @$internal
  @override
  UnreadCountNotifier create() => UnreadCountNotifier();
}

String _$unreadCountNotifierHash() =>
    r'739056aa5f831d2bc1f842984f8eec9a89092d0c';

/// Provides unread message count for badge display

abstract class _$UnreadCountNotifier extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Manages message actions (mark as read, perform action)

@ProviderFor(MessageActionNotifier)
const messageActionProvider = MessageActionNotifierProvider._();

/// Manages message actions (mark as read, perform action)
final class MessageActionNotifierProvider
    extends $NotifierProvider<MessageActionNotifier, MessageActionState> {
  /// Manages message actions (mark as read, perform action)
  const MessageActionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageActionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageActionNotifierHash();

  @$internal
  @override
  MessageActionNotifier create() => MessageActionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageActionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageActionState>(value),
    );
  }
}

String _$messageActionNotifierHash() =>
    r'd7c38de9c3f88f464583a42a9c493b2161fd2256';

/// Manages message actions (mark as read, perform action)

abstract class _$MessageActionNotifier extends $Notifier<MessageActionState> {
  MessageActionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MessageActionState, MessageActionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MessageActionState, MessageActionState>,
              MessageActionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
