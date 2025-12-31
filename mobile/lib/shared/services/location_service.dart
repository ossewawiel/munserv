import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/geo_point.dart';

part 'location_service.g.dart';

/// Service for handling device location
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  /// Returns true if permission is granted
  Future<bool> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User denied permanently, need to open app settings
      return false;
    }

    return true;
  }

  /// Get current location
  /// Returns null if location services are disabled or permission denied
  Future<GeoPoint?> getCurrentLocation() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Open location settings (when permission is denied forever)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (when permission is denied forever)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get permission status
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
}

/// Provider for LocationService
@riverpod
LocationService locationService(Ref ref) {
  return LocationService();
}

/// Provider for getting current location (one-time fetch)
@riverpod
Future<GeoPoint?> currentLocation(Ref ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.getCurrentLocation();
}
