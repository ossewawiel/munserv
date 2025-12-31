// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for LocationService

@ProviderFor(locationService)
const locationServiceProvider = LocationServiceProvider._();

/// Provider for LocationService

final class LocationServiceProvider
    extends
        $FunctionalProvider<LocationService, LocationService, LocationService>
    with $Provider<LocationService> {
  /// Provider for LocationService
  const LocationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationServiceHash();

  @$internal
  @override
  $ProviderElement<LocationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocationService create(Ref ref) {
    return locationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationService>(value),
    );
  }
}

String _$locationServiceHash() => r'38d15292e1d1d4553c8f07a36b00411aa0a8d30e';

/// Provider for getting current location (one-time fetch)

@ProviderFor(currentLocation)
const currentLocationProvider = CurrentLocationProvider._();

/// Provider for getting current location (one-time fetch)

final class CurrentLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<GeoPoint?>,
          GeoPoint?,
          FutureOr<GeoPoint?>
        >
    with $FutureModifier<GeoPoint?>, $FutureProvider<GeoPoint?> {
  /// Provider for getting current location (one-time fetch)
  const CurrentLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLocationHash();

  @$internal
  @override
  $FutureProviderElement<GeoPoint?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GeoPoint?> create(Ref ref) {
    return currentLocation(ref);
  }
}

String _$currentLocationHash() => r'7a2274297da25a371e454a84cc1cb83cbd114a68';
