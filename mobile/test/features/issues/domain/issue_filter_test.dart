import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/domain/issue_filter.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';

void main() {
  group('IssueSortBy', () {
    test('displayName returns correct values', () {
      expect(IssueSortBy.heat.displayName, 'Priority');
      expect(IssueSortBy.createdAt.displayName, 'Date');
    });
  });

  group('IssueFilter', () {
    test('can be created with required fields only', () {
      final filter = IssueFilter(sectorId: 'sector-123');

      expect(filter.sectorId, 'sector-123');
      expect(filter.state, isNull);
      expect(filter.type, isNull);
      expect(filter.page, 1);
      expect(filter.limit, 20);
      expect(filter.sortBy, IssueSortBy.heat);
    });

    test('can be created with all fields', () {
      final filter = IssueFilter(
        sectorId: 'sector-123',
        state: IssueState.reported,
        type: IssueType.pothole,
        page: 2,
        limit: 10,
        sortBy: IssueSortBy.createdAt,
      );

      expect(filter.sectorId, 'sector-123');
      expect(filter.state, IssueState.reported);
      expect(filter.type, IssueType.pothole);
      expect(filter.page, 2);
      expect(filter.limit, 10);
      expect(filter.sortBy, IssueSortBy.createdAt);
    });

    test('toQueryParameters includes required fields', () {
      final filter = IssueFilter(sectorId: 'sector-123');
      final params = filter.toQueryParameters();

      expect(params['sectorId'], 'sector-123');
      expect(params['page'], '1');
      expect(params['limit'], '20');
      expect(params['sortBy'], 'heat');
      expect(params.containsKey('state'), false);
      expect(params.containsKey('type'), false);
    });

    test('toQueryParameters includes optional fields when set', () {
      final filter = IssueFilter(
        sectorId: 'sector-123',
        state: IssueState.confirmed,
        type: IssueType.waterLeak,
        page: 3,
        limit: 50,
        sortBy: IssueSortBy.createdAt,
      );
      final params = filter.toQueryParameters();

      expect(params['sectorId'], 'sector-123');
      expect(params['page'], '3');
      expect(params['limit'], '50');
      expect(params['sortBy'], 'createdAt');
      expect(params['state'], 'confirmed');
      expect(params['type'], 'waterLeak');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = IssueFilter(sectorId: 'sector-123');
      final updated = original.copyWith(
        state: IssueState.inProgress,
        page: 5,
      );

      expect(original.state, isNull);
      expect(original.page, 1);
      expect(updated.sectorId, 'sector-123');
      expect(updated.state, IssueState.inProgress);
      expect(updated.page, 5);
    });

    test('equality works correctly', () {
      final filter1 = IssueFilter(sectorId: 'sector-123', page: 1);
      final filter2 = IssueFilter(sectorId: 'sector-123', page: 1);
      final filter3 = IssueFilter(sectorId: 'sector-456', page: 1);

      expect(filter1, equals(filter2));
      expect(filter1, isNot(equals(filter3)));
    });
  });
}
