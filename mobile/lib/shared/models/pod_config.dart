import 'package:freezed_annotation/freezed_annotation.dart';

part 'pod_config.freezed.dart';
part 'pod_config.g.dart';

/// Pod-specific configuration for branding and localization
/// Each deployment (pod) can have different colors, logos, and supported languages
@freezed
abstract class PodConfig with _$PodConfig {
  const PodConfig._();

  const factory PodConfig({
    required String podId,
    required String podName,
    required String primaryColor,
    required String secondaryColor,
    String? tertiaryColor,
    String? logoUrl,
    String? fontFamily,
    @Default(['en']) List<String> supportedLocales,
    @Default('en') String defaultLocale,
  }) = _PodConfig;

  /// Default configuration for development/testing
  /// Uses Forest Green + Terracotta palette
  static const defaultConfig = PodConfig(
    podId: 'default',
    podName: 'MunServ',
    primaryColor: '#2D4A47',   // Forest Green
    secondaryColor: '#C75B39', // Terracotta
    tertiaryColor: '#E8E4DC',  // Warm Beige
    supportedLocales: ['en'],
    defaultLocale: 'en',
  );

  /// Example configuration for Ward 42 Northcliff
  static const ward42Config = PodConfig(
    podId: 'ward42-northcliff',
    podName: 'Ward 42 Northcliff',
    primaryColor: '#2E7D32',
    secondaryColor: '#FFA000',
    supportedLocales: ['en', 'af', 'zu'],
    defaultLocale: 'en',
  );

  factory PodConfig.fromJson(Map<String, dynamic> json) =>
      _$PodConfigFromJson(json);
}
