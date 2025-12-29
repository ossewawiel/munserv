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
@riverpod
IssueApi issueApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return IssueApi(dio);
}

/// Provides IssueRepository
@riverpod
IssueRepository issueRepository(Ref ref) {
  final api = ref.watch(issueApiProvider);
  return IssueRepository(api);
}

// =============================================================================
// Data Providers
// =============================================================================

/// Current issue filter state - can be modified by UI
@riverpod
class IssueFilterState extends _$IssueFilterState {
  @override
  IssueFilter build() {
    // Get sector from auth state
    final authState = ref.watch(authProvider);
    final sectorId = authState.sectorIdOrNull ?? 'default-sector';
    return IssueFilter(sectorId: sectorId);
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

/// Fetches paginated issues based on current filter
@riverpod
Future<PaginatedIssueSummaries> issues(Ref ref) async {
  final repository = ref.watch(issueRepositoryProvider);
  final filter = ref.watch(issueFilterStateProvider);

  final result = await repository.getIssues(filter);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
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
