import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/issue.dart';
import '../../../shared/models/issue_state.dart';
import '../../../shared/models/issue_type.dart';
import '../../../shared/providers/dio_provider.dart';
import '../../../shared/utils/result.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/issue_api.dart';
import '../data/issue_repository.dart';
import '../domain/domain.dart';

part 'issue_providers.g.dart';

// =============================================================================
// Infrastructure Providers
// =============================================================================

/// Provides IssueApi
/// keepAlive: true to prevent disposal/recreation cycles
@Riverpod(keepAlive: true)
IssueApi issueApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return IssueApi(dio);
}

/// Provides IssueRepository
/// keepAlive: true to prevent disposal/recreation cycles
@Riverpod(keepAlive: true)
IssueRepository issueRepository(Ref ref) {
  final api = ref.watch(issueApiProvider);
  return IssueRepository(api);
}

// =============================================================================
// Data Providers
// =============================================================================

/// Current issue filter state - can be modified by UI
/// keepAlive prevents disposal/recreation cycles that cause infinite fetch loops
@Riverpod(keepAlive: true)
class IssueFilterState extends _$IssueFilterState {
  @override
  IssueFilter build() {
    // Get initial sector from auth state (read, not watch)
    final authState = ref.read(authProvider);
    final initialSectorId = authState.sectorIdOrNull ?? '';

    // Listen for auth changes and update sector only when it actually changes
    ref.listen(authProvider, (previous, next) {
      final previousSectorId = previous?.sectorIdOrNull;
      final nextSectorId = next.sectorIdOrNull;

      // Only update if sector changed and we have a valid new sector
      if (nextSectorId != null &&
          nextSectorId.isNotEmpty &&
          nextSectorId != previousSectorId) {
        state = state.copyWith(sectorId: nextSectorId);
      }
    });

    return IssueFilter(sectorId: initialSectorId);
  }

  /// Update the filter
  void updateFilter(IssueFilter filter) {
    state = filter;
  }

  /// Update just the state filter
  void setStateFilter(IssueState? issueState) {
    state = state.copyWith(state: issueState);
  }

  /// Update just the type filter
  void setTypeFilter(IssueType? type) {
    state = state.copyWith(type: type);
  }

  /// Update sort order
  void setSortBy(IssueSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// Go to next page
  void nextPage() {
    state = state.copyWith(page: state.page + 1);
  }

  /// Go to previous page
  void previousPage() {
    if (state.page > 1) {
      state = state.copyWith(page: state.page - 1);
    }
  }

  /// Reset to first page (when filters change)
  void resetPage() {
    state = state.copyWith(page: 1);
  }

  /// Clear all filters
  void clearFilters() {
    state = IssueFilter(sectorId: state.sectorId);
  }
}

/// Manages issue list data with explicit state control
/// Uses AsyncNotifier pattern for better control over state transitions
@Riverpod(keepAlive: true)
class IssuesNotifier extends _$IssuesNotifier {
  @override
  Future<PaginatedIssueSummaries> build() async {
    // Listen to filter changes and refetch
    ref.listen(issueFilterStateProvider, (previous, next) {
      // Only refetch if filter actually changed (not just object identity)
      if (previous?.sectorId != next.sectorId ||
          previous?.state != next.state ||
          previous?.type != next.type ||
          previous?.page != next.page ||
          previous?.sortBy != next.sortBy) {
        _fetch();
      }
    });

    return _fetchInternal();
  }

  /// Refetch issues (called when filter changes or for refresh)
  Future<void> _fetch() async {
    state = const AsyncLoading();
    try {
      final data = await _fetchInternal();
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Internal fetch logic
  Future<PaginatedIssueSummaries> _fetchInternal() async {
    final repository = ref.read(issueRepositoryProvider);
    final filter = ref.read(issueFilterStateProvider);

    // Don't fetch if no valid sector (user not authenticated yet)
    if (filter.sectorId.isEmpty) {
      return const PaginatedIssueSummaries(
        items: [],
        pagination: Pagination(
          page: 1,
          limit: 20,
          totalItems: 0,
          totalPages: 0,
        ),
      );
    }

    final result = await repository.getIssues(filter);

    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  /// Public method to trigger a refresh
  Future<void> refresh() async {
    await _fetch();
  }
}

/// Fetches a single issue detail by ID
@riverpod
Future<IssueDetail> issueDetail(Ref ref, String issueId) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getIssue(issueId);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// Fetches full Issue model by ID (for map markers)
@riverpod
Future<Issue> issueFull(Ref ref, String issueId) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getIssueFull(issueId);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// Fetches issues reported by the current user
@riverpod
Future<PaginatedIssueSummaries> myIssues(Ref ref, {int page = 1}) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getMyIssues(page: page);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// Provides all issues as a flat list (for map display)
@riverpod
Future<List<IssueSummary>> allIssuesList(Ref ref) async {
  final paginated = await ref.watch(issuesProvider.future);
  return paginated.items;
}

// =============================================================================
// Issue Notifier for Mutations
// =============================================================================

/// State for the report issue form
sealed class ReportIssueState {
  const ReportIssueState();
}

class ReportIssueStateInitial extends ReportIssueState {
  const ReportIssueStateInitial();
}

class ReportIssueStateSubmitting extends ReportIssueState {
  const ReportIssueStateSubmitting();
}

class ReportIssueStateSuccess extends ReportIssueState {
  final ReportIssueResponse response;
  const ReportIssueStateSuccess(this.response);
}

class ReportIssueStateError extends ReportIssueState {
  final String message;
  const ReportIssueStateError(this.message);
}

/// Manages issue reporting
@riverpod
class ReportIssueNotifier extends _$ReportIssueNotifier {
  @override
  ReportIssueState build() => const ReportIssueStateInitial();

  IssueRepository get _repository => ref.read(issueRepositoryProvider);

  /// Submit a new issue report
  Future<Result<ReportIssueResponse>> reportIssue({
    required ReportIssueRequest request,
    required List<String> photoPaths,
  }) async {
    state = const ReportIssueStateSubmitting();

    final result = await _repository.reportIssue(
      request: request,
      photoPaths: photoPaths,
    );

    state = switch (result) {
      Success(:final data) => ReportIssueStateSuccess(data),
      Failure(:final error) => ReportIssueStateError(error.displayMessage),
    };

    // Invalidate issues list to refresh
    if (result.isSuccess) {
      ref.invalidate(issuesProvider);
      ref.invalidate(myIssuesProvider);
    }

    return result;
  }

  /// Reset state to initial
  void reset() {
    state = const ReportIssueStateInitial();
  }
}

// =============================================================================
// Convenience Providers
// =============================================================================

/// Whether we have any issues loaded
@riverpod
bool hasIssues(Ref ref) {
  final issuesAsync = ref.watch(issuesProvider);
  return issuesAsync.whenOrNull(data: (data) => data.items.isNotEmpty) ?? false;
}

/// Total issue count from pagination
@riverpod
int? totalIssueCount(Ref ref) {
  final issuesAsync = ref.watch(issuesProvider);
  return issuesAsync.whenOrNull(data: (data) => data.pagination.totalItems);
}

/// Current page info
@riverpod
Pagination? currentPagination(Ref ref) {
  final issuesAsync = ref.watch(issuesProvider);
  return issuesAsync.whenOrNull(data: (data) => data.pagination);
}
