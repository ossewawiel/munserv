import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/domain/report_issue_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';

void main() {
  group('ReportIssueRequest', () {
    test('can be created with required fields', () {
      final request = ReportIssueRequest(
        type: IssueType.pothole,
        location: const GeoPoint(latitude: -26.1234, longitude: 28.0123),
      );

      expect(request.type, IssueType.pothole);
      expect(request.location.latitude, -26.1234);
      expect(request.location.longitude, 28.0123);
      expect(request.description, isNull);
    });

    test('can be created with optional description', () {
      final request = ReportIssueRequest(
        type: IssueType.waterLeak,
        location: const GeoPoint(latitude: -26.5, longitude: 28.5),
        description: 'Water leaking from pipe',
      );

      expect(request.type, IssueType.waterLeak);
      expect(request.description, 'Water leaking from pipe');
    });

    test('toJson serializes correctly', () {
      final request = ReportIssueRequest(
        type: IssueType.streetLight,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
        description: 'Light is broken',
      );

      final json = request.toJson();

      expect(json['type'], 'street_light');
      expect(json['location']['latitude'], -26.1);
      expect(json['location']['longitude'], 28.1);
      expect(json['description'], 'Light is broken');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'type': 'illegal_dumping',
        'location': {'latitude': -26.2, 'longitude': 28.2},
        'description': 'Rubbish dumped',
      };

      final request = ReportIssueRequest.fromJson(json);

      expect(request.type, IssueType.illegalDumping);
      expect(request.location.latitude, -26.2);
      expect(request.location.longitude, 28.2);
      expect(request.description, 'Rubbish dumped');
    });

    test('equality works correctly', () {
      final request1 = ReportIssueRequest(
        type: IssueType.pothole,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
      );
      final request2 = ReportIssueRequest(
        type: IssueType.pothole,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
      );
      final request3 = ReportIssueRequest(
        type: IssueType.waterLeak,
        location: const GeoPoint(latitude: -26.1, longitude: 28.1),
      );

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });

  group('ReportIssueResponse', () {
    test('can be created from JSON', () {
      final json = {
        'id': 'issue-123',
        'type': 'pothole',
        'state': 'reported',
        'location': {'latitude': -26.1, 'longitude': 28.1},
        'heat': 10,
        'photoUrls': ['https://example.com/photo1.jpg'],
        'createdAt': '2025-01-15T09:00:00.000Z',
      };

      final response = ReportIssueResponse.fromJson(json);

      expect(response.id, 'issue-123');
      expect(response.type, IssueType.pothole);
      expect(response.state, 'reported');
      expect(response.location.latitude, -26.1);
      expect(response.heat, 10);
      expect(response.photoUrls.length, 1);
      expect(response.createdAt, isA<DateTime>());
    });

    test('handles multiple photo URLs', () {
      final json = {
        'id': 'issue-456',
        'type': 'water_leak',
        'state': 'reported',
        'location': {'latitude': -26.2, 'longitude': 28.2},
        'heat': 25,
        'photoUrls': [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
        'createdAt': '2025-01-15T10:00:00.000Z',
      };

      final response = ReportIssueResponse.fromJson(json);

      expect(response.photoUrls.length, 3);
    });
  });
}
