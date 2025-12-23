import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum IssueType {
  pothole,
  waterLeak,
  sewageLeak,
  trafficLight,
  streetLight,
  illegalDumping,
  other;

  String get displayName => switch (this) {
        pothole => 'Pothole',
        waterLeak => 'Water Leak',
        sewageLeak => 'Sewage Leak',
        trafficLight => 'Traffic Light',
        streetLight => 'Street Light',
        illegalDumping => 'Illegal Dumping',
        other => 'Other',
      };
}
