import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/ground_admin.dart';
import '../../../shared/providers/dio_provider.dart';
import '../../../shared/utils/result.dart';
import '../data/ground_admin_api.dart';
import '../data/ground_admin_repository.dart';

part 'ground_admin_providers.g.dart';

// =============================================================================
// Infrastructure Providers
// =============================================================================

/// Provides GroundAdminApi
@Riverpod(keepAlive: true)
GroundAdminApi groundAdminApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return GroundAdminApi(dio);
}

/// Provides GroundAdminRepository
@Riverpod(keepAlive: true)
GroundAdminRepository groundAdminRepository(Ref ref) {
  final api = ref.watch(groundAdminApiProvider);
  return GroundAdminRepository(api);
}

// =============================================================================
// Data Providers
// =============================================================================

/// Current user's Ground Admin info (null if not a Ground Admin)
@Riverpod(keepAlive: true)
class MyGroundAdminInfoNotifier extends _$MyGroundAdminInfoNotifier {
  @override
  Future<GroundAdminInfo?> build() async {
    final repository = ref.read(groundAdminRepositoryProvider);
    final result = await repository.getMyGroundAdminInfo();

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(groundAdminRepositoryProvider);
      final result = await repository.getMyGroundAdminInfo();
      state = AsyncData(switch (result) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Whether current user is a Ground Admin
@riverpod
bool isGroundAdmin(Ref ref) {
  final infoAsync = ref.watch(myGroundAdminInfoProvider);
  return infoAsync.value != null;
}

// =============================================================================
// Ground Admin Application/Invitation
// =============================================================================

/// State for Ground Admin application/invitation actions
sealed class GroundAdminActionState {
  const GroundAdminActionState();
}

class GroundAdminActionStateIdle extends GroundAdminActionState {
  const GroundAdminActionStateIdle();
}

class GroundAdminActionStateLoading extends GroundAdminActionState {
  const GroundAdminActionStateLoading();
}

class GroundAdminActionStateSuccess extends GroundAdminActionState {
  final String message;
  const GroundAdminActionStateSuccess(this.message);
}

class GroundAdminActionStateError extends GroundAdminActionState {
  final String message;
  const GroundAdminActionStateError(this.message);
}

/// Manages Ground Admin application and invitation actions
@Riverpod(keepAlive: true)
class GroundAdminActionNotifier extends _$GroundAdminActionNotifier {
  @override
  GroundAdminActionState build() => const GroundAdminActionStateIdle();

  /// Apply to become a Ground Admin
  Future<Result<GroundAdminApplication>> apply() async {
    state = const GroundAdminActionStateLoading();

    final repository = ref.read(groundAdminRepositoryProvider);
    final result = await repository.apply();

    if (ref.mounted) {
      state = switch (result) {
        Success() => const GroundAdminActionStateSuccess(
          'Application submitted',
        ),
        Failure(:final error) => GroundAdminActionStateError(
          error.displayMessage,
        ),
      };
    }

    return result;
  }

  /// Accept a Ground Admin invitation
  Future<Result<GroundAdminActionResponse>> acceptInvitation(
    String applicationId,
  ) async {
    state = const GroundAdminActionStateLoading();

    final repository = ref.read(groundAdminRepositoryProvider);
    final result = await repository.acceptInvitation(applicationId);

    if (ref.mounted) {
      state = switch (result) {
        Success() => const GroundAdminActionStateSuccess(
          'You are now a Ground Admin',
        ),
        Failure(:final error) => GroundAdminActionStateError(
          error.displayMessage,
        ),
      };

      if (result.isSuccess) {
        // Refresh Ground Admin info
        ref.read(myGroundAdminInfoProvider.notifier).refresh();
      }
    }

    return result;
  }

  /// Decline a Ground Admin invitation
  Future<Result<void>> declineInvitation(
    String applicationId, {
    String? reason,
  }) async {
    state = const GroundAdminActionStateLoading();

    final repository = ref.read(groundAdminRepositoryProvider);
    final result = await repository.declineInvitation(
      applicationId,
      reason: reason,
    );

    if (ref.mounted) {
      state = switch (result) {
        Success() => const GroundAdminActionStateSuccess('Invitation declined'),
        Failure(:final error) => GroundAdminActionStateError(
          error.displayMessage,
        ),
      };
    }

    return result;
  }

  /// Request to step down from Ground Admin role
  Future<Result<void>> stepDown({String? reason}) async {
    state = const GroundAdminActionStateLoading();

    final repository = ref.read(groundAdminRepositoryProvider);
    final result = await repository.stepDown(reason: reason);

    if (ref.mounted) {
      state = switch (result) {
        Success() => const GroundAdminActionStateSuccess(
          'Step down request submitted',
        ),
        Failure(:final error) => GroundAdminActionStateError(
          error.displayMessage,
        ),
      };

      if (result.isSuccess) {
        // Refresh Ground Admin info
        ref.read(myGroundAdminInfoProvider.notifier).refresh();
      }
    }

    return result;
  }

  void reset() {
    state = const GroundAdminActionStateIdle();
  }
}
