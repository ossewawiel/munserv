// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sector _$SectorFromJson(Map<String, dynamic> json) => _Sector(
  id: json['id'] as String,
  name: json['name'] as String,
  center: GeoPoint.fromJson(json['center'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SectorToJson(_Sector instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'center': instance.center,
};
