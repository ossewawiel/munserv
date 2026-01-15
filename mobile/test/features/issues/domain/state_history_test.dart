import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/domain/state_history.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';

void main() {
  group('StateHistoryEntry', () {
    test('can be created with required fields only', () {
      final entry = StateHistoryEntry(
        state: IssueState.reported,
        changedAt: DateTime(2025, 1, 14, 8, 30),
      );

      expect(entry.state, IssueState.reported);
      expect(entry.changedAt, DateTime(2025, 1, 14, 8, 30));
      expect(entry.changedBy, isNull);
      expect(entry.note, isNull);
    });

    test('can be created with all fields', () {
      final entry = StateHistoryEntry(
        state: IssueState.confirmed,
        changedAt: DateTime(2025, 1, 14, 10, 15),
        changedBy: 'admin-uuid',
        note: 'Verified on site',
      );

      expect(entry.state, IssueState.confirmed);
      expect(entry.changedBy, 'admin-uuid');
      expect(entry.note, 'Verified on site');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'state': 'confirmed',
        'changedAt': '2025-01-14T10:15:00.000Z',
        'changedBy': 'admin-123',
        'note': 'Verified',
      };

      final entry = StateHistoryEntry.fromJson(json);

      expect(entry.state, IssueState.confirmed);
      expect(entry.changedBy, 'admin-123');
      expect(entry.note, 'Verified');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'state': 'reported',
        'changedAt': '2025-01-14T08:30:00.000Z',
        'changedBy': null,
        'note': null,
      };

      final entry = StateHistoryEntry.fromJson(json);

      expect(entry.state, IssueState.reported);
      expect(entry.changedBy, isNull);
      expect(entry.note, isNull);
    });

    test('equality works correctly', () {
      final entry1 = StateHistoryEntry(
        state: IssueState.confirmed,
        changedAt: DateTime(2025, 1, 14, 10, 15),
        changedBy: 'admin-123',
      );
      final entry2 = StateHistoryEntry(
        state: IssueState.confirmed,
        changedAt: DateTime(2025, 1, 14, 10, 15),
        changedBy: 'admin-123',
      );
      final entry3 = StateHistoryEntry(
        state: IssueState.inProgress,
        changedAt: DateTime(2025, 1, 14, 10, 15),
        changedBy: 'admin-123',
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });
  });

  group('IssueDetail', () {
    test('can be created from JSON with state history', () {
      final json = {
        'id': 'issue-1',
        'type': 'pothole',
        'state': 'confirmed',
        'location': {'latitude': -26.1234, 'longitude': 28.0123},
        'address': '123 Main Road',
        'description': 'Large pothole',
        'heat': 75,
        'photoUrls': ['https://example.com/photo1.jpg'],
        'sectorId': 'sector-1',
        'reporterId': 'member-1',
        'reportCount': 3,
        'createdAt': '2025-01-14T08:30:00.000Z',
        'updatedAt': '2025-01-14T10:15:00.000Z',
        'stateHistory': [
          {
            'state': 'reported',
            'changedAt': '2025-01-14T08:30:00.000Z',
            'changedBy': null,
            'note': null,
          },
          {
            'state': 'confirmed',
            'changedAt': '2025-01-14T10:15:00.000Z',
            'changedBy': 'admin-uuid',
            'note': 'Verified on site',
          },
        ],
      };

      final detail = IssueDetail.fromJson(json);

      expect(detail.id, 'issue-1');
      expect(detail.type, 'pothole');
      expect(detail.state, 'confirmed');
      expect(detail.latitude, -26.1234);
      expect(detail.longitude, 28.0123);
      expect(detail.address, '123 Main Road');
      expect(detail.description, 'Large pothole');
      expect(detail.heat, 75);
      expect(detail.photoUrls.length, 1);
      expect(detail.reportCount, 3);
      expect(detail.stateHistory.length, 2);
      expect(detail.stateHistory[0].state, IssueState.reported);
      expect(detail.stateHistory[1].state, IssueState.confirmed);
      expect(detail.stateHistory[1].note, 'Verified on site');
    });

    test('handles empty state history', () {
      final json = {
        'id': 'issue-2',
        'type': 'water_leak',
        'state': 'reported',
        'location': {'latitude': -26.2, 'longitude': 28.2},
        'heat': 50,
        'photoUrls': <String>[],
        'sectorId': 'sector-1',
        'reporterId': 'member-2',
        'reportCount': 1,
        'createdAt': '2025-01-15T09:00:00.000Z',
        'updatedAt': '2025-01-15T09:00:00.000Z',
      };

      final detail = IssueDetail.fromJson(json);

      expect(detail.stateHistory, isEmpty);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'issue-3',
        'type': 'other',
        'state': 'reported',
        'location': {'latitude': -26.3, 'longitude': 28.3},
        'address': null,
        'description': null,
        'heat': 10,
        'photoUrls': ['https://example.com/photo.jpg'],
        'sectorId': 'sector-1',
        'reporterId': 'member-3',
        'reportCount': 1,
        'createdAt': '2025-01-15T10:00:00.000Z',
        'updatedAt': '2025-01-15T10:00:00.000Z',
      };

      final detail = IssueDetail.fromJson(json);

      expect(detail.address, isNull);
      expect(detail.description, isNull);
    });
  });
}
