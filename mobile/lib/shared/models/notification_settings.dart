import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';
part 'notification_settings.g.dart';

/// User notification preferences
@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const NotificationSettings._();

  const factory NotificationSettings({
    required bool pushEnabled,
    required bool verificationAlerts,
    required bool monthlyReports,
  }) = _NotificationSettings;

  /// Default notification settings for new users
  factory NotificationSettings.defaults() => const NotificationSettings(
        pushEnabled: true,
        verificationAlerts: true,
        monthlyReports: true,
      );

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
