import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/registration_request.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

void main() {
  group('RegistrationRequest', () {
    test('can be created with all required fields', () {
      const request = RegistrationRequest(
        firstName: 'John',
        surname: 'Doe',
        pin: '1234',
        location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
        address: '42 Doreen Road, Northcliff',
      );

      expect(request.firstName, 'John');
      expect(request.surname, 'Doe');
      expect(request.pin, '1234');
      expect(request.location.latitude, -26.1350);
      expect(request.location.longitude, 27.9800);
      expect(request.address, '42 Doreen Road, Northcliff');
    });

    test('toJson serializes correctly', () {
      const request = RegistrationRequest(
        firstName: 'John',
        surname: 'Doe',
        pin: '1234',
        location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
        address: '42 Doreen Road, Northcliff',
      );

      final json = request.toJson();

      expect(json['firstName'], 'John');
      expect(json['surname'], 'Doe');
      expect(json['pin'], '1234');
      expect(json['address'], '42 Doreen Road, Northcliff');
      // Nested objects are serialized as maps with explicit_to_json: true
      final locationJson = json['location'] as Map<String, dynamic>;
      expect(locationJson['latitude'], -26.1350);
      expect(locationJson['longitude'], 27.9800);
    });

    test('fromJson deserializes correctly', () {
      final request = RegistrationRequest.fromJson({
        'firstName': 'John',
        'surname': 'Doe',
        'pin': '1234',
        'location': {'latitude': -26.1350, 'longitude': 27.9800},
        'address': '42 Doreen Road, Northcliff',
      });

      expect(request.firstName, 'John');
      expect(request.surname, 'Doe');
      expect(request.pin, '1234');
      expect(request.location.latitude, -26.1350);
      expect(request.address, '42 Doreen Road, Northcliff');
    });

    test('equality works correctly', () {
      const request1 = RegistrationRequest(
        firstName: 'John',
        surname: 'Doe',
        pin: '1234',
        location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
        address: '42 Doreen Road, Northcliff',
      );
      const request2 = RegistrationRequest(
        firstName: 'John',
        surname: 'Doe',
        pin: '1234',
        location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
        address: '42 Doreen Road, Northcliff',
      );
      const request3 = RegistrationRequest(
        firstName: 'Jane',
        surname: 'Doe',
        pin: '1234',
        location: GeoPoint(latitude: -26.1350, longitude: 27.9800),
        address: '42 Doreen Road, Northcliff',
      );

      expect(request1, request2);
      expect(request1, isNot(request3));
    });
  });

  group('GeoPoint', () {
    test('can be created with coordinates', () {
      const point = GeoPoint(latitude: -26.1350, longitude: 27.9800);

      expect(point.latitude, -26.1350);
      expect(point.longitude, 27.9800);
    });

    test('toJson serializes correctly', () {
      const point = GeoPoint(latitude: -26.1350, longitude: 27.9800);

      expect(point.toJson(), {
        'latitude': -26.1350,
        'longitude': 27.9800,
      });
    });

    test('fromJson deserializes correctly', () {
      final point = GeoPoint.fromJson({
        'latitude': -26.1350,
        'longitude': 27.9800,
      });

      expect(point.latitude, -26.1350);
      expect(point.longitude, 27.9800);
    });
  });
}
