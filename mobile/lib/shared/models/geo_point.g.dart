// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeoPoint _$GeoPointFromJson(Map<String, dynamic> json) => _GeoPoint(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$GeoPointToJson(_GeoPoint instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
