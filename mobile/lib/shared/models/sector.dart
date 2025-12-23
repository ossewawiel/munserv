import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'sector.freezed.dart';
part 'sector.g.dart';

@freezed
abstract class Sector with _$Sector {
  const factory Sector({
    required String id,
    required String name,
    required GeoPoint center,
  }) = _Sector;

  factory Sector.fromJson(Map<String, dynamic> json) => _$SectorFromJson(json);
}
