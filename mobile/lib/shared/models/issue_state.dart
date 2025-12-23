import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum IssueState {
  reported,
  confirmed,
  inProgress,
  fixed,
  rejected;

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
