import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/issues/data/issue_api.dart';
import 'package:munserv_mobile/features/issues/data/issue_repository.dart';
import 'package:munserv_mobile/features/issues/domain/domain.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/utils/result.dart';

class MockIssueApi extends Mock implements IssueApi {}

void main() {
  late MockIssueApi mockApi;
  late IssueRepository repository;

  setUpAll(() {
    registerFallbackValue(IssueFilter(sectorId: 'test'));
    registerFallbackValue(
      ReportIssueRequest(
        type: IssueType.pothole,
        location: const GeoPoint(latitude: 0, longitude: 0),
        sectorId: 'fallback-sector',
      ),
    );
  });

  setUp(() {
    mockApi = MockIssueApi();
    repository = IssueRepository(mockApi);
  });

  group('IssueRepository', () {
    group('getIssues', () {
      test('returns Success with PaginatedIssueSummaries on success', () async {
        final mockResponse = PaginatedIssueSummaries(
          items: [
            IssueSummary(
              id: 'issue-1',
              type: IssueType.pothole,
              state: IssueState.reported,
              location: const GeoPoint(latitude: -26.1, longitude: 28.1),
              heat: 75,
              thumbnailUrl: 'https://example.com/thumb1.jpg',
              createdAt: DateTime.now(),
            ),
          ],
          pagination: const Pagination(
            page: 1,
            limit: 20,
            totalItems: 1,
            totalPages: 1,
          ),
        );

        when(
          () => mockApi.getIssues(any()),
        ).thenAnswer((_) async => mockResponse);

        final filter = IssueFilter(sectorId: 'sector-1');
        final result = await repository.getIssues(filter);

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.items.length, 1);
        expect(result.dataOrNull?.items[0].id, 'issue-1');
      });

      test('returns Failure on DioException', () async {
        when(() => mockApi.getIssues(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(),
            ),
          ),
        );

        final filter = IssueFilter(sectorId: 'sector-1');
        final result = await repository.getIssues(filter);

        expect(result.isSuccess, false);
        expect(result.errorOrNull, isNotNull);
      });

      test('returns Failure on unknown exception', () async {
        when(
          () => mockApi.getIssues(any()),
        ).thenThrow(Exception('Network error'));

        final filter = IssueFilter(sectorId: 'sector-1');
        final result = await repository.getIssues(filter);

        expect(result.isSuccess, false);
        expect(result.errorOrNull?.message, contains('Network error'));
      });
    });

    group('getIssue', () {
      test('returns Success with IssueDetail on success', () async {
        final mockResponse = IssueDetail(
          id: 'issue-1',
          type: 'pothole',
          state: 'confirmed',
          latitude: -26.1234,
          longitude: 28.0123,
          heat: 75,
          photoUrls: ['https://example.com/photo.jpg'],
          sectorId: 'sector-1',
          reporterId: 'member-1',
          reportCount: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => mockApi.getIssue('issue-1'),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.getIssue('issue-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'issue-1');
        expect(result.dataOrNull?.type, 'pothole');
      });

      test('returns Failure on 404', () async {
        when(() => mockApi.getIssue('not-found')).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 404,
              data: {'error': 'Issue not found'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        final result = await repository.getIssue('not-found');

        expect(result.isSuccess, false);
        expect(result.errorOrNull, isNotNull);
      });
    });

    group('getMyIssues', () {
      test('returns Success with my issues on success', () async {
        final mockResponse = PaginatedIssueSummaries(
          items: [
            IssueSummary(
              id: 'my-issue-1',
              type: IssueType.waterLeak,
              state: IssueState.inProgress,
              location: const GeoPoint(latitude: -26.2, longitude: 28.2),
              heat: 50,
              thumbnailUrl: 'https://example.com/thumb2.jpg',
              createdAt: DateTime.now(),
            ),
          ],
          pagination: const Pagination(
            page: 1,
            limit: 20,
            totalItems: 1,
            totalPages: 1,
          ),
        );

        when(
          () => mockApi.getMyIssues(page: 1, limit: 20),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.getMyIssues();

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.items.length, 1);
        expect(result.dataOrNull?.items[0].id, 'my-issue-1');
      });

      test('returns Failure on error', () async {
        when(
          () => mockApi.getMyIssues(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(DioException(requestOptions: RequestOptions()));

        final result = await repository.getMyIssues();

        expect(result.isSuccess, false);
      });
    });

    group('reportIssue', () {
      test('returns Success with ReportIssueResponse on success', () async {
        final mockResponse = ReportIssueResponse(
          id: 'new-issue-1',
          type: IssueType.pothole,
          state: 'reported',
          location: const GeoPoint(latitude: -26.1, longitude: 28.1),
          heat: 10,
          photoUrls: ['https://example.com/uploaded.jpg'],
          createdAt: DateTime.now(),
        );

        when(
          () => mockApi.reportIssue(
            request: any(named: 'request'),
            photoPaths: any(named: 'photoPaths'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final request = ReportIssueRequest(
          type: IssueType.pothole,
          location: const GeoPoint(latitude: -26.1, longitude: 28.1),
          sectorId: 'sector-123',
        );

        final result = await repository.reportIssue(
          request: request,
          photoPaths: ['/path/to/photo.jpg'],
        );

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'new-issue-1');
        expect(result.dataOrNull?.type, IssueType.pothole);
      });

      test('returns Failure on validation error', () async {
        when(
          () => mockApi.reportIssue(
            request: any(named: 'request'),
            photoPaths: any(named: 'photoPaths'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 400,
              data: {'error': 'Photo required'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        final request = ReportIssueRequest(
          type: IssueType.pothole,
          location: const GeoPoint(latitude: -26.1, longitude: 28.1),
          sectorId: 'sector-456',
        );

        final result = await repository.reportIssue(
          request: request,
          photoPaths: [],
        );

        expect(result.isSuccess, false);
      });
    });

    group('getIssueFull', () {
      test('returns Success with Issue model on success', () async {
        final mockResponse = Issue(
          id: 'issue-1',
          type: IssueType.pothole,
          state: IssueState.confirmed,
          location: const GeoPoint(latitude: -26.1234, longitude: 28.0123),
          heat: 75,
          photoUrls: ['https://example.com/photo.jpg'],
          sectorId: 'sector-1',
          reporterId: 'member-1',
          reportCount: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => mockApi.getIssueFull('issue-1'),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.getIssueFull('issue-1');

        expect(result.isSuccess, true);
        expect(result.dataOrNull?.id, 'issue-1');
        expect(result.dataOrNull?.type, IssueType.pothole);
      });
    });
  });
}
