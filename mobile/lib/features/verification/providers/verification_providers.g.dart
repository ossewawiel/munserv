// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides VerificationApi

@ProviderFor(verificationApi)
const verificationApiProvider = VerificationApiProvider._();

/// Provides VerificationApi

final class VerificationApiProvider
    extends
        $FunctionalProvider<VerificationApi, VerificationApi, VerificationApi>
    with $Provider<VerificationApi> {
  /// Provides VerificationApi
  const VerificationApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationApiHash();

  @$internal
  @override
  $ProviderElement<VerificationApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerificationApi create(Ref ref) {
    return verificationApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerificationApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerificationApi>(value),
    );
  }
}

String _$verificationApiHash() => r'cfd692c6a5d1bb46cc7d92377dc806e8db9a03e3';

/// Provides VerificationRepository

@ProviderFor(verificationRepository)
const verificationRepositoryProvider = VerificationRepositoryProvider._();

/// Provides VerificationRepository

final class VerificationRepositoryProvider
    extends
        $FunctionalProvider<
          VerificationRepository,
          VerificationRepository,
          VerificationRepository
        >
    with $Provider<VerificationRepository> {
  /// Provides VerificationRepository
  const VerificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<VerificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VerificationRepository create(Ref ref) {
    return verificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerificationRepository>(value),
    );
  }
}

String _$verificationRepositoryHash() =>
    r'9411cf2c4600560178f4795eb67131e9cdd3f8e9';

/// Pending verifications for current Ground Admin

@ProviderFor(PendingVerificationsNotifier)
const pendingVerificationsProvider = PendingVerificationsNotifierProvider._();

/// Pending verifications for current Ground Admin
final class PendingVerificationsNotifierProvider
    extends
        $AsyncNotifierProvider<
          PendingVerificationsNotifier,
          List<PendingVerification>
        > {
  /// Pending verifications for current Ground Admin
  const PendingVerificationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingVerificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingVerificationsNotifierHash();

  @$internal
  @override
  PendingVerificationsNotifier create() => PendingVerificationsNotifier();
}

String _$pendingVerificationsNotifierHash() =>
    r'9b9d77e5c69648cf55e7dc89a3d492c25541db2c';

/// Pending verifications for current Ground Admin

abstract class _$PendingVerificationsNotifier
    extends $AsyncNotifier<List<PendingVerification>> {
  FutureOr<List<PendingVerification>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<PendingVerification>>,
              List<PendingVerification>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PendingVerification>>,
                List<PendingVerification>
              >,
              AsyncValue<List<PendingVerification>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Count of pending verifications

@ProviderFor(pendingVerificationCount)
const pendingVerificationCountProvider = PendingVerificationCountProvider._();

/// Count of pending verifications

final class PendingVerificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Count of pending verifications
  const PendingVerificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingVerificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingVerificationCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pendingVerificationCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pendingVerificationCountHash() =>
    r'6b7bfef72df78754692e2555c5e2356ba7bb5583';

/// Manages verification submission

@ProviderFor(VerificationSubmitNotifier)
const verificationSubmitProvider = VerificationSubmitNotifierProvider._();

/// Manages verification submission
final class VerificationSubmitNotifierProvider
    extends
        $NotifierProvider<VerificationSubmitNotifier, VerificationSubmitState> {
  /// Manages verification submission
  const VerificationSubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationSubmitProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationSubmitNotifierHash();

  @$internal
  @override
  VerificationSubmitNotifier create() => VerificationSubmitNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerificationSubmitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerificationSubmitState>(value),
    );
  }
}

String _$verificationSubmitNotifierHash() =>
    r'43ae4ea3acccc988a2fe4c8098393786f16ea884';

/// Manages verification submission

abstract class _$VerificationSubmitNotifier
    extends $Notifier<VerificationSubmitState> {
  VerificationSubmitState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<VerificationSubmitState, VerificationSubmitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VerificationSubmitState, VerificationSubmitState>,
              VerificationSubmitState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Verification history for a specific issue

@ProviderFor(verificationHistory)
const verificationHistoryProvider = VerificationHistoryFamily._();

/// Verification history for a specific issue

final class VerificationHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IssueVerification>>,
          List<IssueVerification>,
          FutureOr<List<IssueVerification>>
        >
    with
        $FutureModifier<List<IssueVerification>>,
        $FutureProvider<List<IssueVerification>> {
  /// Verification history for a specific issue
  const VerificationHistoryProvider._({
    required VerificationHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'verificationHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$verificationHistoryHash();

  @override
  String toString() {
    return r'verificationHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<IssueVerification>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IssueVerification>> create(Ref ref) {
    final argument = this.argument as String;
    return verificationHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VerificationHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$verificationHistoryHash() =>
    r'025e837c41cbff533cb689b12bcda79440ecfd31';

/// Verification history for a specific issue

final class VerificationHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<IssueVerification>>, String> {
  const VerificationHistoryFamily._()
    : super(
        retry: null,
        name: r'verificationHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Verification history for a specific issue

  VerificationHistoryProvider call(String issueId) =>
      VerificationHistoryProvider._(argument: issueId, from: this);

  @override
  String toString() => r'verificationHistoryProvider';
}

/// User's notification settings

@ProviderFor(NotificationSettingsNotifier)
const notificationSettingsProvider = NotificationSettingsNotifierProvider._();

/// User's notification settings
final class NotificationSettingsNotifierProvider
    extends
        $AsyncNotifierProvider<
          NotificationSettingsNotifier,
          NotificationSettings
        > {
  /// User's notification settings
  const NotificationSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsNotifierHash();

  @$internal
  @override
  NotificationSettingsNotifier create() => NotificationSettingsNotifier();
}

String _$notificationSettingsNotifierHash() =>
    r'64eb7f582a1758e5664e31e27b17c878b8846536';

/// User's notification settings

abstract class _$NotificationSettingsNotifier
    extends $AsyncNotifier<NotificationSettings> {
  FutureOr<NotificationSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<NotificationSettings>, NotificationSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NotificationSettings>,
                NotificationSettings
              >,
              AsyncValue<NotificationSettings>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
