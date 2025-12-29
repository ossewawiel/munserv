import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/features/issues/data/issue_api.dart';
import 'package:munserv_mobile/features/issues/domain/domain.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';

class MockDio extends Mock implements Dio {}

/// Test data for issue responses
final testIssueSummary = {
  'id': 'issue-1',
  'type': 'pothole',
  'state': 'reported',
  'location': {'latitude': -26.1234, 'longitude': 28.0123},
  'heat': 75,
  'thumbnailUrl': 'https://example.com/thumb1.jpg',
  'createdAt': '2025-01-14T08:30:00.000Z',
};

final testIssueDetail = {
  'id': 'issue-1',
  'type': 'pothole',
  'state': 'confirmed',
  'latitude': -26.1234,
  'longitude': 28.0123,
  'address': '123 Main Road',
  'description': 'Large pothole in road',
  'heat': 75,
  'photoUrls': ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
  'sectorId': 'sector-1',
  'reporterId': 'member-1',
  'reportCount': 3,
  'createdAt': '2025-01-14T08:30:00.000Z',
  'updatedAt': '2025-01-14T10:15:00.000Z',
  'stateHistory': [
    {
      'state': 'reported',
      'changedAt': '2025-01-14T08:30:00.000Z',
    },
    {
      'state': 'confirmed',
      'changedAt': '2025-01-14T10:15:00.000Z',
      'changedBy': 'admin-uuid',
      'note': 'Verified on site',
    },
  ],
};

void main() {
  late MockDio mockDio;
  late IssueApi issueApi;

  setUp(() {
    mockDio = MockDio();
    issueApi = IssueApi(mockDio);
  });

  group('IssueApi', () {
    group('getIssues', () {
      test('calls GET /issues with query parameters', () async {
        when(() => mockDio.get(
              '/issues',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'items': [testIssueSummary],
                'pagination': {
                  'page': 1,
                  'limit': 20,
                  'totalItems': 1,
                  'totalPages': 1,
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final filter = IssueFilter(sectorId: 'sector-1');
        final result = await issueApi.getIssues(filter);

        expect(result.items.length, 1);
        expect(result.items[0].id, 'issue-1');
        expect(result.pagination.totalItems, 1);

        verify(() => mockDio.get(
              '/issues',
              queryParameters: {
                'sectorId': 'sector-1',
                'page': '1',
                'limit': '20',
                'sortBy': 'heat',
              },
            )).called(1);
      });

      test('includes optional filters in query parameters', () async {
        when(() => mockDio.get(
              '/issues',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'items': <Map<String, dynamic>>[],
                'pagination': {
                  'page': 2,
                  'limit': 10,
                  'totalItems': 0,
                  'totalPages': 0,
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final filter = IssueFilter(
          sectorId: 'sector-1',
          state: IssueState.confirmed,
          type: IssueType.waterLeak,
          page: 2,
          limit: 10,
          sortBy: IssueSortBy.createdAt,
        );
        await issueApi.getIssues(filter);

        verify(() => mockDio.get(
              '/issues',
              queryParameters: {
                'sectorId': 'sector-1',
                'page': '2',
                'limit': '10',
                'sortBy': 'createdAt',
                'state': 'confirmed',
                'type': 'waterLeak',
              },
            )).called(1);
      });
    });

    group('getIssue', () {
      test('calls GET /issues/{issueId} and returns detail', () async {
        when(() => mockDio.get('/issues/issue-1'))
            .thenAnswer((_) async => Response(
                  data: testIssueDetail,
                  statusCode: 200,
                  requestOptions: RequestOptions(),
                ));

        final result = await issueApi.getIssue('issue-1');

        expect(result.id, 'issue-1');
        expect(result.type, 'pothole');
        expect(result.state, 'confirmed');
        expect(result.latitude, -26.1234);
        expect(result.stateHistory.length, 2);
        expect(result.stateHistory[1].note, 'Verified on site');

        verify(() => mockDio.get('/issues/issue-1')).called(1);
      });
    });

    group('getMyIssues', () {
      test('calls GET /issues/mine with pagination', () async {
        when(() => mockDio.get(
              '/issues/mine',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'items': [testIssueSummary],
                'pagination': {
                  'page': 1,
                  'limit': 20,
                  'totalItems': 1,
                  'totalPages': 1,
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final result = await issueApi.getMyIssues(page: 1, limit: 20);

        expect(result.items.length, 1);
        expect(result.items[0].id, 'issue-1');

        verify(() => mockDio.get(
              '/issues/mine',
              queryParameters: {'page': '1', 'limit': '20'},
            )).called(1);
      });
    });

    group('reportIssue', () {
      test('calls POST /issues with multipart form data', () async {
        when(() => mockDio.post(
              '/issues',
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              data: {
                'id': 'new-issue-1',
                'type': 'pothole',
                'state': 'reported',
                'location': {'latitude': -26.1, 'longitude': 28.1},
                'heat': 10,
                'photoUrls': ['https://example.com/uploaded.jpg'],
                'createdAt': '2025-01-15T09:00:00.000Z',
              },
              statusCode: 201,
              requestOptions: RequestOptions(),
            ));

        final request = ReportIssueRequest(
          type: IssueType.pothole,
          location: const GeoPoint(latitude: -26.1, longitude: 28.1),
          description: 'Large pothole',
        );

        // Note: We can't actually test file upload without real files
        // This test verifies the API call structure
        final result = await issueApi.reportIssue(
          request: request,
          photoPaths: [], // Empty for unit test
        );

        expect(result.id, 'new-issue-1');
        expect(result.type, IssueType.pothole);
        expect(result.state, 'reported');
        expect(result.heat, 10);

        verify(() => mockDio.post(
              '/issues',
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).called(1);
      });
    });

    group('getIssueFull', () {
      test('calls GET /issues/{issueId} and returns Issue model', () async {
        when(() => mockDio.get('/issues/issue-1'))
            .thenAnswer((_) async => Response(
                  data: {
                    'id': 'issue-1',
                    'type': 'pothole',
                    'state': 'confirmed',
                    'location': {'latitude': -26.1234, 'longitude': 28.0123},
                    'heat': 75,
                    'photoUrls': ['https://example.com/photo1.jpg'],
                    'sectorId': 'sector-1',
                    'reporterId': 'member-1',
                    'reportCount': 3,
                    'createdAt': '2025-01-14T08:30:00.000Z',
                    'updatedAt': '2025-01-14T10:15:00.000Z',
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(),
                ));

        final result = await issueApi.getIssueFull('issue-1');

        expect(result.id, 'issue-1');
        expect(result.type, IssueType.pothole);
        expect(result.state, IssueState.confirmed);
        expect(result.heat, 75);

        verify(() => mockDio.get('/issues/issue-1')).called(1);
      });
    });
  });
}
