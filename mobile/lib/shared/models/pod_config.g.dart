// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pod_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PodConfig _$PodConfigFromJson(Map<String, dynamic> json) => _PodConfig(
  podId: json['podId'] as String,
  podName: json['podName'] as String,
  primaryColor: json['primaryColor'] as String,
  secondaryColor: json['secondaryColor'] as String,
  tertiaryColor: json['tertiaryColor'] as String?,
  logoUrl: json['logoUrl'] as String?,
  fontFamily: json['fontFamily'] as String?,
  supportedLocales:
      (json['supportedLocales'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['en'],
  defaultLocale: json['defaultLocale'] as String? ?? 'en',
);

Map<String, dynamic> _$PodConfigToJson(_PodConfig instance) =>
    <String, dynamic>{
      'podId': instance.podId,
      'podName': instance.podName,
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'tertiaryColor': instance.tertiaryColor,
      'logoUrl': instance.logoUrl,
      'fontFamily': instance.fontFamily,
      'supportedLocales': instance.supportedLocales,
      'defaultLocale': instance.defaultLocale,
    };
