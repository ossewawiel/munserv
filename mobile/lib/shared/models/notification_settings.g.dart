// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => _NotificationSettings(
  pushEnabled: json['pushEnabled'] as bool,
  verificationAlerts: json['verificationAlerts'] as bool,
  monthlyReports: json['monthlyReports'] as bool,
);

Map<String, dynamic> _$NotificationSettingsToJson(
  _NotificationSettings instance,
) => <String, dynamic>{
  'pushEnabled': instance.pushEnabled,
  'verificationAlerts': instance.verificationAlerts,
  'monthlyReports': instance.monthlyReports,
};
