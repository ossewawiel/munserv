// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides VerificationApi

@ProviderFor(verificationApi)
final verificationApiProvider = VerificationApiProvider._();

/// Provides VerificationApi

final class VerificationApiProvider
    extends
        $FunctionalProvider<VerificationApi, VerificationApi, VerificationApi>
    with $Provider<VerificationApi> {
  /// Provides VerificationApi
  VerificationApiProvider._()
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
final verificationRepositoryProvider = VerificationRepositoryProvider._();

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
  VerificationRepositoryProvider._()
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
final pendingVerificationsProvider = PendingVerificationsNotifierProvider._();

/// Pending verifications for current Ground Admin
final class PendingVerificationsNotifierProvider
    extends
        $AsyncNotifierProvider<
          PendingVerificationsNotifier,
          List<PendingVerification>
        > {
  /// Pending verifications for current Ground Admin
  PendingVerificationsNotifierProvider._()
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
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}

/// Count of pending verifications

@ProviderFor(pendingVerificationCount)
final pendingVerificationCountProvider = PendingVerificationCountProvider._();

/// Count of pending verifications

final class PendingVerificationCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Count of pending verifications
  PendingVerificationCountProvider._()
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
    r'f932f4f5003c67f3a3ba4a39154643ab6af37a40';

/// Manages verification submission

@ProviderFor(VerificationSubmitNotifier)
final verificationSubmitProvider = VerificationSubmitNotifierProvider._();

/// Manages verification submission
final class VerificationSubmitNotifierProvider
    extends
        $NotifierProvider<VerificationSubmitNotifier, VerificationSubmitState> {
  /// Manages verification submission
  VerificationSubmitNotifierProvider._()
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
    r'3c60e1acd59450a114328d6cc3880bb6a1276be3';

/// Manages verification submission

abstract class _$VerificationSubmitNotifier
    extends $Notifier<VerificationSubmitState> {
  VerificationSubmitState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}

/// Verification history for a specific issue

@ProviderFor(verificationHistory)
final verificationHistoryProvider = VerificationHistoryFamily._();

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
  VerificationHistoryProvider._({
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
  VerificationHistoryFamily._()
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
final notificationSettingsProvider = NotificationSettingsNotifierProvider._();

/// User's notification settings
final class NotificationSettingsNotifierProvider
    extends
        $AsyncNotifierProvider<
          NotificationSettingsNotifier,
          NotificationSettings
        > {
  /// User's notification settings
  NotificationSettingsNotifierProvider._()
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
    r'859e8900cc1c6a8ece86c583357f626bb56f04aa';

/// User's notification settings

abstract class _$NotificationSettingsNotifier
    extends $AsyncNotifier<NotificationSettings> {
  FutureOr<NotificationSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
