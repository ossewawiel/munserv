import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum IssueState {
  reported,
  confirmed,
  inProgress,
  fixed,
  rejected;

  /// Parse from API string (snake_case format)
  static IssueState fromString(String value) => switch (value) {
    'reported' => reported,
    'confirmed' => confirmed,
    'in_progress' => inProgress,
    'fixed' => fixed,
    'rejected' => rejected,
    _ => reported, // Default to reported for unknown states
  };

  /// Convert to API string (snake_case format)
  String toApiString() => switch (this) {
    reported => 'reported',
    confirmed => 'confirmed',
    inProgress => 'in_progress',
    fixed => 'fixed',
    rejected => 'rejected',
  };

  String get displayName => switch (this) {
    reported => 'Reported',
    confirmed => 'Confirmed',
    inProgress => 'In Progress',
    fixed => 'Fixed',
    rejected => 'Rejected',
  };

  Set<IssueState> get allowedTransitions => switch (this) {
    reported => {confirmed, rejected},
    confirmed => {inProgress, rejected},
    inProgress => {fixed, rejected},
    fixed => {},
    rejected => {},
  };
}
