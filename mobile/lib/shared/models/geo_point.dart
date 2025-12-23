import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_point.freezed.dart';
part 'geo_point.g.dart';

@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({
    required double latitude,
    required double longitude,
  }) = _GeoPoint;

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      _$GeoPointFromJson(json);
}
