import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum IssueType {
  pothole,
  waterLeak,
  sewageLeak,
  trafficLight,
  streetLight,
  illegalDumping,
  roadDamage,
  other;

  /// Parse from API string (snake_case format)
  static IssueType fromString(String value) => switch (value) {
    'pothole' => pothole,
    'water_leak' => waterLeak,
    'sewage_leak' => sewageLeak,
    'traffic_light' => trafficLight,
    'street_light' => streetLight,
    'illegal_dumping' => illegalDumping,
    'road_damage' => roadDamage,
    _ => other,
  };

  /// Convert to API string (snake_case format)
  String toApiString() => switch (this) {
    pothole => 'pothole',
    waterLeak => 'water_leak',
    sewageLeak => 'sewage_leak',
    trafficLight => 'traffic_light',
    streetLight => 'street_light',
    illegalDumping => 'illegal_dumping',
    roadDamage => 'road_damage',
    other => 'other',
  };

  String get displayName => switch (this) {
    pothole => 'Pothole',
    waterLeak => 'Water Leak',
    sewageLeak => 'Sewage Leak',
    trafficLight => 'Traffic Light',
    streetLight => 'Street Light',
    illegalDumping => 'Illegal Dumping',
    roadDamage => 'Road Damage',
    other => 'Other',
  };
}
