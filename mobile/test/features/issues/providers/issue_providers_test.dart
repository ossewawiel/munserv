import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/issues/data/issue_repository.dart';
import 'package:munserv_mobile/features/issues/domain/domain.dart';
import 'package:munserv_mobile/features/issues/providers/issue_providers.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/utils/app_error.dart';
import 'package:munserv_mobile/shared/utils/result.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

/// Test data
final testIssueSummary = IssueSummary(
  id: 'issue-1',
  type: IssueType.pothole,
  state: IssueState.reported,
  location: const GeoPoint(latitude: -26.1234, longitude: 28.0123),
  heat: 75,
  thumbnailUrl: 'https://example.com/thumb1.jpg',
  createdAt: DateTime(2025, 1, 14, 8, 30),
);

final testPaginatedIssues = PaginatedIssueSummaries(
  items: [testIssueSummary],
  pagination: const Pagination(
    page: 1,
    limit: 20,
    totalItems: 1,
    totalPages: 1,
  ),
);

final testIssueDetail = IssueDetail(
  id: 'issue-1',
  type: 'pothole',
  state: 'confirmed',
  latitude: -26.1234,
  longitude: 28.0123,
  address: '123 Main Road',
  description: 'Large pothole',
  heat: 75,
  photoUrls: ['https://example.com/photo1.jpg'],
  sectorId: 'sector-1',
  reporterId: 'member-1',
  reportCount: 3,
  createdAt: DateTime(2025, 1, 14, 8, 30),
  updatedAt: DateTime(2025, 1, 14, 10, 15),
  stateHistory: [
    StateHistoryEntry(
      state: IssueState.reported,
      changedAt: DateTime(2025, 1, 14, 8, 30),
    ),
    StateHistoryEntry(
      state: IssueState.confirmed,
      changedAt: DateTime(2025, 1, 14, 10, 15),
      changedBy: 'admin-uuid',
    ),
  ],
);

final testReportResponse = ReportIssueResponse(
  id: 'new-issue-1',
  type: IssueType.pothole,
  state: 'reported',
  location: const GeoPoint(latitude: -26.1, longitude: 28.1),
  heat: 10,
  photoUrls: ['https://example.com/uploaded.jpg'],
  createdAt: DateTime(2025, 1, 15, 9, 0),
);

void main() {
  late MockIssueRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(IssueFilter(sectorId: 'test'));
    registerFallbackValue(ReportIssueRequest(
      type: IssueType.pothole,
      location: const GeoPoint(latitude: 0, longitude: 0),
    ));
  });

  setUp(() {
    mockRepository = MockIssueRepository();
  });

  group('ReportIssueState', () {
    test('initial state is ReportIssueStateInitial', () {
      const state = ReportIssueStateInitial();
      expect(state, isA<ReportIssueStateInitial>());
    });

    test('submitting state is ReportIssueStateSubmitting', () {
      const state = ReportIssueStateSubmitting();
      expect(state, isA<ReportIssueStateSubmitting>());
    });

    test('success state contains response', () {
      final state = ReportIssueStateSuccess(testReportResponse);
      expect(state, isA<ReportIssueStateSuccess>());
      expect(state.response.id, 'new-issue-1');
    });

    test('error state contains message', () {
      const state = ReportIssueStateError('Upload failed');
      expect(state, isA<ReportIssueStateError>());
      expect(state.message, 'Upload failed');
    });
  });

  group('IssueFilter', () {
    test('can be created with just sectorId', () {
      final filter = IssueFilter(sectorId: 'sector-1');
      expect(filter.sectorId, 'sector-1');
      expect(filter.state, isNull);
      expect(filter.type, isNull);
      expect(filter.page, 1);
      expect(filter.limit, 20);
      expect(filter.sortBy, IssueSortBy.heat);
    });

    test('copyWith preserves unchanged values', () {
      final filter = IssueFilter(sectorId: 'sector-1');
      final updated = filter.copyWith(state: IssueState.confirmed);

      expect(updated.sectorId, 'sector-1');
      expect(updated.state, IssueState.confirmed);
      expect(updated.page, 1);
    });
  });

  group('IssueRepository integration', () {
    test('getIssues returns paginated issues on success', () async {
      when(() => mockRepository.getIssues(any()))
          .thenAnswer((_) async => Result.success(testPaginatedIssues));

      final filter = IssueFilter(sectorId: 'sector-1');
      final result = await mockRepository.getIssues(filter);

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.items.length, 1);
      expect(result.dataOrNull?.items[0].id, 'issue-1');
    });

    test('getIssue returns issue detail on success', () async {
      when(() => mockRepository.getIssue('issue-1'))
          .thenAnswer((_) async => Result.success(testIssueDetail));

      final result = await mockRepository.getIssue('issue-1');

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.id, 'issue-1');
      expect(result.dataOrNull?.stateHistory.length, 2);
    });

    test('reportIssue returns response on success', () async {
      when(() => mockRepository.reportIssue(
            request: any(named: 'request'),
            photoPaths: any(named: 'photoPaths'),
          )).thenAnswer((_) async => Result.success(testReportResponse));

      final request = ReportIssueRequest(
        type: IssueType.pothole,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
      );

      final result = await mockRepository.reportIssue(
        request: request,
        photoPaths: ['/path/to/photo.jpg'],
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull?.id, 'new-issue-1');
    });

    test('reportIssue returns failure on error', () async {
      when(() => mockRepository.reportIssue(
            request: any(named: 'request'),
            photoPaths: any(named: 'photoPaths'),
          )).thenAnswer((_) async => const Result.failure(
            AppError.validation(message: 'Photo required'),
          ));

      final request = ReportIssueRequest(
        type: IssueType.pothole,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
      );

      final result = await mockRepository.reportIssue(
        request: request,
        photoPaths: [],
      );

      expect(result.isSuccess, false);
      expect(result.errorOrNull?.message, 'Photo required');
    });
  });

  group('Provider container tests', () {
    test('issueRepositoryProvider creates IssueRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // This will throw if provider setup is wrong
      expect(
        () => container.read(issueRepositoryProvider),
        returnsNormally,
      );
    });

    test('issueApiProvider creates IssueApi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(issueApiProvider),
        returnsNormally,
      );
    });

    test('reportIssueProvider starts with initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(reportIssueProvider);
      expect(state, isA<ReportIssueStateInitial>());
    });
  });
}
