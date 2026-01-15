import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/domain/paginated_issues.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';

void main() {
  group('Pagination', () {
    test('can be created with required fields', () {
      const pagination = Pagination(
        page: 1,
        limit: 20,
        totalItems: 45,
        totalPages: 3,
      );

      expect(pagination.page, 1);
      expect(pagination.limit, 20);
      expect(pagination.totalItems, 45);
      expect(pagination.totalPages, 3);
    });

    test('hasNextPage returns true when more pages exist', () {
      const pagination = Pagination(
        page: 1,
        limit: 20,
        totalItems: 45,
        totalPages: 3,
      );

      expect(pagination.hasNextPage, true);
    });

    test('hasNextPage returns false on last page', () {
      const pagination = Pagination(
        page: 3,
        limit: 20,
        totalItems: 45,
        totalPages: 3,
      );

      expect(pagination.hasNextPage, false);
    });

    test('hasPreviousPage returns false on first page', () {
      const pagination = Pagination(
        page: 1,
        limit: 20,
        totalItems: 45,
        totalPages: 3,
      );

      expect(pagination.hasPreviousPage, false);
    });

    test('hasPreviousPage returns true after first page', () {
      const pagination = Pagination(
        page: 2,
        limit: 20,
        totalItems: 45,
        totalPages: 3,
      );

      expect(pagination.hasPreviousPage, true);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'page': 2,
        'limit': 10,
        'totalItems': 100,
        'totalPages': 10,
      };

      final pagination = Pagination.fromJson(json);

      expect(pagination.page, 2);
      expect(pagination.limit, 10);
      expect(pagination.totalItems, 100);
      expect(pagination.totalPages, 10);
    });
  });

  group('PaginatedIssueSummaries', () {
    test('can be created from JSON', () {
      final json = {
        'items': [
          {
            'id': 'issue-1',
            'type': 'pothole',
            'state': 'reported',
            'location': {'latitude': -26.1, 'longitude': 28.1},
            'heat': 75,
            'thumbnailUrl': 'https://example.com/thumb1.jpg',
            'createdAt': '2025-01-14T08:30:00.000Z',
          },
          {
            'id': 'issue-2',
            'type': 'water_leak',
            'state': 'confirmed',
            'location': {'latitude': -26.2, 'longitude': 28.2},
            'heat': 50,
            'thumbnailUrl': 'https://example.com/thumb2.jpg',
            'createdAt': '2025-01-13T10:00:00.000Z',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 20,
          'totalItems': 45,
          'totalPages': 3,
        },
      };

      final paginated = PaginatedIssueSummaries.fromJson(json);

      expect(paginated.items.length, 2);
      expect(paginated.items[0].id, 'issue-1');
      expect(paginated.items[0].type, IssueType.pothole);
      expect(paginated.items[1].id, 'issue-2');
      expect(paginated.items[1].type, IssueType.waterLeak);
      expect(paginated.pagination.page, 1);
      expect(paginated.pagination.totalItems, 45);
    });

    test('handles empty items list', () {
      final json = {
        'items': <Map<String, dynamic>>[],
        'pagination': {
          'page': 1,
          'limit': 20,
          'totalItems': 0,
          'totalPages': 0,
        },
      };

      final paginated = PaginatedIssueSummaries.fromJson(json);

      expect(paginated.items, isEmpty);
      expect(paginated.pagination.totalItems, 0);
    });
  });

  group('PaginatedIssues', () {
    test('can be created with full issue objects', () {
      final now = DateTime.now();
      final issues = [
        Issue(
          id: 'issue-1',
          type: IssueType.pothole,
          state: IssueState.reported,
          location: const GeoPoint(latitude: -26.1, longitude: 28.1),
          heat: 75,
          photoUrls: ['https://example.com/photo1.jpg'],
          sectorId: 'sector-1',
          reporterId: 'member-1',
          reportCount: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      const pagination = Pagination(
        page: 1,
        limit: 20,
        totalItems: 1,
        totalPages: 1,
      );

      final paginated = PaginatedIssues(items: issues, pagination: pagination);

      expect(paginated.items.length, 1);
      expect(paginated.items[0].id, 'issue-1');
      expect(paginated.pagination.totalItems, 1);
    });
  });
}
