// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides IssueApi
/// keepAlive: true to prevent disposal/recreation cycles

@ProviderFor(issueApi)
const issueApiProvider = IssueApiProvider._();

/// Provides IssueApi
/// keepAlive: true to prevent disposal/recreation cycles

final class IssueApiProvider
    extends $FunctionalProvider<IssueApi, IssueApi, IssueApi>
    with $Provider<IssueApi> {
  /// Provides IssueApi
  /// keepAlive: true to prevent disposal/recreation cycles
  const IssueApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'issueApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$issueApiHash();

  @$internal
  @override
  $ProviderElement<IssueApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IssueApi create(Ref ref) {
    return issueApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IssueApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IssueApi>(value),
    );
  }
}

String _$issueApiHash() => r'5a369a3e67089e2efc45633aafcde6db6cda5f3b';

/// Provides IssueRepository
/// keepAlive: true to prevent disposal/recreation cycles

@ProviderFor(issueRepository)
const issueRepositoryProvider = IssueRepositoryProvider._();

/// Provides IssueRepository
/// keepAlive: true to prevent disposal/recreation cycles

final class IssueRepositoryProvider
    extends
        $FunctionalProvider<IssueRepository, IssueRepository, IssueRepository>
    with $Provider<IssueRepository> {
  /// Provides IssueRepository
  /// keepAlive: true to prevent disposal/recreation cycles
  const IssueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'issueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$issueRepositoryHash();

  @$internal
  @override
  $ProviderElement<IssueRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IssueRepository create(Ref ref) {
    return issueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IssueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IssueRepository>(value),
    );
  }
}

String _$issueRepositoryHash() => r'3f9c733584e68535569139a978dd7462de47e842';

/// Current issue filter state - can be modified by UI
/// keepAlive prevents disposal/recreation cycles that cause infinite fetch loops

@ProviderFor(IssueFilterState)
const issueFilterStateProvider = IssueFilterStateProvider._();

/// Current issue filter state - can be modified by UI
/// keepAlive prevents disposal/recreation cycles that cause infinite fetch loops
final class IssueFilterStateProvider
    extends $NotifierProvider<IssueFilterState, IssueFilter> {
  /// Current issue filter state - can be modified by UI
  /// keepAlive prevents disposal/recreation cycles that cause infinite fetch loops
  const IssueFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'issueFilterStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$issueFilterStateHash();

  @$internal
  @override
  IssueFilterState create() => IssueFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IssueFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IssueFilter>(value),
    );
  }
}

String _$issueFilterStateHash() => r'1466682560677b283956adb0342410f99bf5e305';

/// Current issue filter state - can be modified by UI
/// keepAlive prevents disposal/recreation cycles that cause infinite fetch loops

abstract class _$IssueFilterState extends $Notifier<IssueFilter> {
  IssueFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<IssueFilter, IssueFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IssueFilter, IssueFilter>,
              IssueFilter,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Manages issue list data with explicit state control
/// Uses AsyncNotifier pattern for better control over state transitions

@ProviderFor(IssuesNotifier)
const issuesProvider = IssuesNotifierProvider._();

/// Manages issue list data with explicit state control
/// Uses AsyncNotifier pattern for better control over state transitions
final class IssuesNotifierProvider
    extends $AsyncNotifierProvider<IssuesNotifier, PaginatedIssueSummaries> {
  /// Manages issue list data with explicit state control
  /// Uses AsyncNotifier pattern for better control over state transitions
  const IssuesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'issuesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$issuesNotifierHash();

  @$internal
  @override
  IssuesNotifier create() => IssuesNotifier();
}

String _$issuesNotifierHash() => r'0c92f9857d6b78b2ba5374bc13b0b328f87e84e6';

/// Manages issue list data with explicit state control
/// Uses AsyncNotifier pattern for better control over state transitions

abstract class _$IssuesNotifier
    extends $AsyncNotifier<PaginatedIssueSummaries> {
  FutureOr<PaginatedIssueSummaries> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PaginatedIssueSummaries>,
              PaginatedIssueSummaries
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PaginatedIssueSummaries>,
                PaginatedIssueSummaries
              >,
              AsyncValue<PaginatedIssueSummaries>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Fetches a single issue detail by ID

@ProviderFor(issueDetail)
const issueDetailProvider = IssueDetailFamily._();

/// Fetches a single issue detail by ID

final class IssueDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<IssueDetail>,
          IssueDetail,
          FutureOr<IssueDetail>
        >
    with $FutureModifier<IssueDetail>, $FutureProvider<IssueDetail> {
  /// Fetches a single issue detail by ID
  const IssueDetailProvider._({
    required IssueDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'issueDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$issueDetailHash();

  @override
  String toString() {
    return r'issueDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<IssueDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IssueDetail> create(Ref ref) {
    final argument = this.argument as String;
    return issueDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IssueDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$issueDetailHash() => r'9cd7b8f265916bcb386ac88cd7221353b231a1dc';

/// Fetches a single issue detail by ID

final class IssueDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<IssueDetail>, String> {
  const IssueDetailFamily._()
    : super(
        retry: null,
        name: r'issueDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single issue detail by ID

  IssueDetailProvider call(String issueId) =>
      IssueDetailProvider._(argument: issueId, from: this);

  @override
  String toString() => r'issueDetailProvider';
}

/// Fetches full Issue model by ID (for map markers)

@ProviderFor(issueFull)
const issueFullProvider = IssueFullFamily._();

/// Fetches full Issue model by ID (for map markers)

final class IssueFullProvider
    extends $FunctionalProvider<AsyncValue<Issue>, Issue, FutureOr<Issue>>
    with $FutureModifier<Issue>, $FutureProvider<Issue> {
  /// Fetches full Issue model by ID (for map markers)
  const IssueFullProvider._({
    required IssueFullFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'issueFullProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$issueFullHash();

  @override
  String toString() {
    return r'issueFullProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Issue> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Issue> create(Ref ref) {
    final argument = this.argument as String;
    return issueFull(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IssueFullProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$issueFullHash() => r'a00fd3dad32d6069c76816ff4b6767938315e582';

/// Fetches full Issue model by ID (for map markers)

final class IssueFullFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Issue>, String> {
  const IssueFullFamily._()
    : super(
        retry: null,
        name: r'issueFullProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches full Issue model by ID (for map markers)

  IssueFullProvider call(String issueId) =>
      IssueFullProvider._(argument: issueId, from: this);

  @override
  String toString() => r'issueFullProvider';
}

/// Fetches issues reported by the current user

@ProviderFor(myIssues)
const myIssuesProvider = MyIssuesFamily._();

/// Fetches issues reported by the current user

final class MyIssuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedIssueSummaries>,
          PaginatedIssueSummaries,
          FutureOr<PaginatedIssueSummaries>
        >
    with
        $FutureModifier<PaginatedIssueSummaries>,
        $FutureProvider<PaginatedIssueSummaries> {
  /// Fetches issues reported by the current user
  const MyIssuesProvider._({
    required MyIssuesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'myIssuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myIssuesHash();

  @override
  String toString() {
    return r'myIssuesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PaginatedIssueSummaries> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedIssueSummaries> create(Ref ref) {
    final argument = this.argument as int;
    return myIssues(ref, page: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyIssuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myIssuesHash() => r'73e56ed328149339ae5aa89d41d1ab8f20705e97';

/// Fetches issues reported by the current user

final class MyIssuesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PaginatedIssueSummaries>, int> {
  const MyIssuesFamily._()
    : super(
        retry: null,
        name: r'myIssuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches issues reported by the current user

  MyIssuesProvider call({int page = 1}) =>
      MyIssuesProvider._(argument: page, from: this);

  @override
  String toString() => r'myIssuesProvider';
}

/// Provides all issues as a flat list (for map display)

@ProviderFor(allIssuesList)
const allIssuesListProvider = AllIssuesListProvider._();

/// Provides all issues as a flat list (for map display)

final class AllIssuesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IssueSummary>>,
          List<IssueSummary>,
          FutureOr<List<IssueSummary>>
        >
    with
        $FutureModifier<List<IssueSummary>>,
        $FutureProvider<List<IssueSummary>> {
  /// Provides all issues as a flat list (for map display)
  const AllIssuesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allIssuesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allIssuesListHash();

  @$internal
  @override
  $FutureProviderElement<List<IssueSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IssueSummary>> create(Ref ref) {
    return allIssuesList(ref);
  }
}

String _$allIssuesListHash() => r'9f393c1a00c1e754be58d6086a0d603f06861034';

/// Manages issue reporting

@ProviderFor(ReportIssueNotifier)
const reportIssueProvider = ReportIssueNotifierProvider._();

/// Manages issue reporting
final class ReportIssueNotifierProvider
    extends $NotifierProvider<ReportIssueNotifier, ReportIssueState> {
  /// Manages issue reporting
  const ReportIssueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportIssueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportIssueNotifierHash();

  @$internal
  @override
  ReportIssueNotifier create() => ReportIssueNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportIssueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportIssueState>(value),
    );
  }
}

String _$reportIssueNotifierHash() =>
    r'4c55b8cbb0f4a3f3f8d93e81b41c431046ec0311';

/// Manages issue reporting

abstract class _$ReportIssueNotifier extends $Notifier<ReportIssueState> {
  ReportIssueState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ReportIssueState, ReportIssueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportIssueState, ReportIssueState>,
              ReportIssueState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Whether we have any issues loaded

@ProviderFor(hasIssues)
const hasIssuesProvider = HasIssuesProvider._();

/// Whether we have any issues loaded

final class HasIssuesProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether we have any issues loaded
  const HasIssuesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasIssuesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasIssuesHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasIssues(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasIssuesHash() => r'3b5db1bc112e4bb31efbaa371c134289c017b24c';

/// Total issue count from pagination

@ProviderFor(totalIssueCount)
const totalIssueCountProvider = TotalIssueCountProvider._();

/// Total issue count from pagination

final class TotalIssueCountProvider
    extends $FunctionalProvider<int?, int?, int?>
    with $Provider<int?> {
  /// Total issue count from pagination
  const TotalIssueCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalIssueCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalIssueCountHash();

  @$internal
  @override
  $ProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int? create(Ref ref) {
    return totalIssueCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$totalIssueCountHash() => r'b2f000c1694422d270cdea3edddcfa6b95ff3e2b';

/// Current page info

@ProviderFor(currentPagination)
const currentPaginationProvider = CurrentPaginationProvider._();

/// Current page info

final class CurrentPaginationProvider
    extends $FunctionalProvider<Pagination?, Pagination?, Pagination?>
    with $Provider<Pagination?> {
  /// Current page info
  const CurrentPaginationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPaginationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPaginationHash();

  @$internal
  @override
  $ProviderElement<Pagination?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Pagination? create(Ref ref) {
    return currentPagination(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Pagination? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Pagination?>(value),
    );
  }
}

String _$currentPaginationHash() => r'78394f0afbc6f18fca6c1bc23cc606975019ecbb';
