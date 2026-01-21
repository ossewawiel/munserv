import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/notification_settings.dart';
import '../../../shared/models/verification.dart';
import '../../../shared/providers/dio_provider.dart';
import '../../../shared/utils/result.dart';
import '../data/verification_api.dart';
import '../data/verification_repository.dart';

part 'verification_providers.g.dart';

// =============================================================================
// Infrastructure Providers
// =============================================================================

/// Provides VerificationApi
@Riverpod(keepAlive: true)
VerificationApi verificationApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return VerificationApi(dio);
}

/// Provides VerificationRepository
@Riverpod(keepAlive: true)
VerificationRepository verificationRepository(Ref ref) {
  final api = ref.watch(verificationApiProvider);
  return VerificationRepository(api);
}

// =============================================================================
// Pending Verifications
// =============================================================================

/// Pending verifications for current Ground Admin
@Riverpod(keepAlive: true)
class PendingVerificationsNotifier extends _$PendingVerificationsNotifier {
  @override
  Future<List<PendingVerification>> build() async {
    final repository = ref.read(verificationRepositoryProvider);
    final result = await repository.getPendingVerifications();

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(verificationRepositoryProvider);
      final result = await repository.getPendingVerifications();
      state = AsyncData(switch (result) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Count of pending verifications
@riverpod
int pendingVerificationCount(Ref ref) {
  final verificationsAsync = ref.watch(pendingVerificationsProvider);
  return verificationsAsync.value?.length ?? 0;
}

// =============================================================================
// Verification Submission
// =============================================================================

/// State for verification submission
sealed class VerificationSubmitState {
  const VerificationSubmitState();
}

class VerificationSubmitStateIdle extends VerificationSubmitState {
  const VerificationSubmitStateIdle();
}

class VerificationSubmitStateLoading extends VerificationSubmitState {
  const VerificationSubmitStateLoading();
}

class VerificationSubmitStateSuccess extends VerificationSubmitState {
  final IssueVerification verification;
  const VerificationSubmitStateSuccess(this.verification);
}

class VerificationSubmitStateError extends VerificationSubmitState {
  final String message;
  const VerificationSubmitStateError(this.message);
}

/// Manages verification submission
@Riverpod(keepAlive: true)
class VerificationSubmitNotifier extends _$VerificationSubmitNotifier {
  @override
  VerificationSubmitState build() => const VerificationSubmitStateIdle();

  /// Submit a verification result
  Future<Result<IssueVerification>> submit({
    required String issueId,
    required String verificationId,
    required String result,
    VerificationReason? reason,
    String? note,
    File? photo,
  }) async {
    state = const VerificationSubmitStateLoading();

    final repository = ref.read(verificationRepositoryProvider);
    final submitResult = await repository.submitVerification(
      issueId: issueId,
      verificationId: verificationId,
      result: result,
      reason: reason?.name,
      note: note,
      photo: photo,
    );

    if (ref.mounted) {
      state = switch (submitResult) {
        Success(:final data) => VerificationSubmitStateSuccess(data),
        Failure(:final error) => VerificationSubmitStateError(
          error.displayMessage,
        ),
      };

      if (submitResult.isSuccess) {
        // Refresh pending verifications list
        ref.read(pendingVerificationsProvider.notifier).refresh();
      }
    }

    return submitResult;
  }

  void reset() {
    state = const VerificationSubmitStateIdle();
  }
}

// =============================================================================
// Verification History
// =============================================================================

/// Verification history for a specific issue
@riverpod
Future<List<IssueVerification>> verificationHistory(
  Ref ref,
  String issueId,
) async {
  final repository = ref.watch(verificationRepositoryProvider);
  final result = await repository.getVerificationHistory(issueId);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

// =============================================================================
// Notification Settings
// =============================================================================

/// User's notification settings
@Riverpod(keepAlive: true)
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  Future<NotificationSettings> build() async {
    final repository = ref.read(verificationRepositoryProvider);
    final result = await repository.getNotificationSettings();

    return switch (result) {
      Success(:final data) => data,
      Failure() => NotificationSettings.defaults(), // Use defaults on error
    };
  }

  /// Update notification settings
  Future<Result<NotificationSettings>> saveSettings(
    NotificationSettings settings,
  ) async {
    final previousState = state;
    state = AsyncData(settings); // Optimistic update

    final repository = ref.read(verificationRepositoryProvider);
    final result = await repository.updateNotificationSettings(settings);

    if (ref.mounted) {
      state = switch (result) {
        Success(:final data) => AsyncData(data),
        Failure() => previousState, // Revert on error
      };
    }

    return result;
  }

  /// Toggle push notifications
  Future<void> togglePushEnabled() async {
    final current = state.value;
    if (current == null) return;
    await saveSettings(current.copyWith(pushEnabled: !current.pushEnabled));
  }

  /// Toggle verification alerts
  Future<void> toggleVerificationAlerts() async {
    final current = state.value;
    if (current == null) return;
    await saveSettings(
      current.copyWith(verificationAlerts: !current.verificationAlerts),
    );
  }

  /// Toggle monthly reports
  Future<void> toggleMonthlyReports() async {
    final current = state.value;
    if (current == null) return;
    await saveSettings(
      current.copyWith(monthlyReports: !current.monthlyReports),
    );
  }
}
