# Freezed Model Generator

name: "model"
description: "Generate Freezed data class with JSON serialization"
parameters:
  - name: "name"
    description: "Model name in PascalCase (e.g., 'Issue', 'Member', 'GeoPoint')"
    required: true
  - name: "feature"
    description: "Feature folder (e.g., 'issues', 'members', 'shared')"
    required: true
  - name: "fields"
    description: "Comma-separated fields (e.g., 'id:String,name:String?,count:int')"
    required: true

---

You are an expert Flutter developer generating Freezed models for the MunServ mobile app.

## Task

Generate a Freezed model named `{{name}}` with fields: `{{fields}}`.

## File Location

```
lib/features/{{feature}}/domain/{{snake_case(name)}}.dart
```

## Basic Freezed Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{snake_case(name)}}.freezed.dart';
part '{{snake_case(name)}}.g.dart';

/// {{name}} domain model
///
/// Represents a {{description}}.
@freezed
class {{name}} with _${{name}} {
  const {{name}}._(); // Private constructor for custom methods

  const factory {{name}}({
    required String id,
    // Generated from {{fields}}
    {{#each fields}}
    {{#if required}}required {{/if}}{{type}} {{name}},
    {{/each}}
  }) = _{{name}};

  /// Create from JSON (API response)
  factory {{name}}.fromJson(Map<String, dynamic> json) =>
      _${{name}}FromJson(json);
}
```

## Model with Custom Methods

```dart
@freezed
class Issue with _$Issue {
  const Issue._();

  const factory Issue({
    required String id,
    required String sectorId,
    required IssueType type,
    required IssueState state,
    required GeoPoint location,
    required int heat,
    required DateTime reportedAt,
    String? description,
    List<String>? photos,
  }) = _Issue;

  /// Check if issue can transition to new state
  bool canTransitionTo(IssueState newState) =>
      state.allowedTransitions.contains(newState);

  /// Get display label for heat level
  String get heatLabel => switch (heat) {
    >= 80 => 'Critical',
    >= 60 => 'High',
    >= 40 => 'Medium',
    _ => 'Low',
  };

  /// Check if issue is actionable
  bool get isActionable => state != IssueState.fixed && state != IssueState.rejected;

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
}
```

## Model with Computed Properties

```dart
@freezed
class Member with _$Member {
  const Member._();

  const factory Member({
    required String id,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? avatarUrl,
    required DateTime joinedAt,
  }) = _Member;

  /// Full name computed from first and last name
  String get fullName => '$firstName $lastName';

  /// Initials for avatar placeholder
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  /// Check if member has email
  bool get hasEmail => email != null && email!.isNotEmpty;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
```

## Value Object (Simple)

```dart
@freezed
class GeoPoint with _$GeoPoint {
  const GeoPoint._();

  const factory GeoPoint({
    required double latitude,
    required double longitude,
  }) = _GeoPoint;

  /// Distance to another point in meters (Haversine formula)
  double distanceTo(GeoPoint other) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(other.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      _$GeoPointFromJson(json);
}
```

## Enum with Extensions

```dart
// lib/features/{{feature}}/domain/{{snake_case(name)}}_state.dart
enum {{name}}State {
  reported,
  confirmed,
  inProgress,
  fixed,
  rejected,
  reopened;

  /// States this state can transition to
  Set<{{name}}State> get allowedTransitions => switch (this) {
    reported => {confirmed, rejected},
    confirmed => {inProgress, rejected},
    inProgress => {fixed, rejected},
    fixed => {reopened},
    rejected => {},
    reopened => {confirmed},
  };

  /// Human-readable display name
  String get displayName => switch (this) {
    reported => 'Reported',
    confirmed => 'Confirmed',
    inProgress => 'In Progress',
    fixed => 'Fixed',
    rejected => 'Rejected',
    reopened => 'Reopened',
  };

  /// Whether state represents an active issue
  bool get isActive => this != fixed && this != rejected;

  /// Parse from API string (handles snake_case)
  static {{name}}State fromString(String value) {
    return {{name}}State.values.firstWhere(
      (s) => s.name == value || s.name == value.replaceAll('_', ''),
      orElse: () => throw ArgumentError('Unknown state: $value'),
    );
  }
}
```

## Union Types (Sealed Classes)

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppError error) = Failure<T>;
}

// Usage with pattern matching
final result = await repository.getIssue(id);
switch (result) {
  case Success(:final data):
    return data;
  case Failure(:final error):
    showError(error.message);
    return null;
}
```

## JSON Serialization Annotations

```dart
@freezed
class IssueDto with _$IssueDto {
  const IssueDto._();

  const factory IssueDto({
    required String id,
    @JsonKey(name: 'sector_id') required String sectorId,
    @JsonKey(name: 'issue_type') required String type,
    @JsonKey(name: 'issue_state') required String state,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'heat_score') required int heat,
    @JsonKey(name: 'reported_at') required String reportedAt,
    @JsonKey(includeIfNull: false) String? description,
    @JsonKey(defaultValue: []) List<String> photos,
  }) = _IssueDto;

  factory IssueDto.fromJson(Map<String, dynamic> json) =>
      _$IssueDtoFromJson(json);

  Issue toDomain() => Issue(
    id: id,
    sectorId: sectorId,
    type: IssueType.fromString(type),
    state: IssueState.fromString(state),
    location: GeoPoint(latitude: latitude, longitude: longitude),
    heat: heat,
    reportedAt: DateTime.parse(reportedAt),
    description: description,
    photos: photos,
  );
}
```

## Best Practices

### Do
- [ ] Add private constructor `const {{name}}._()` for custom methods
- [ ] Use `required` for non-nullable fields
- [ ] Add KDoc comments for public API
- [ ] Use computed getters instead of methods for simple derivations
- [ ] Keep models pure (no side effects)

### Don't
- [ ] Don't add Flutter dependencies in domain models
- [ ] Don't use `late` in Freezed models
- [ ] Don't mutate - use `copyWith()` instead
- [ ] Don't add async methods to models

## Post-Generation Commands

```bash
# Generate Freezed code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Output

1. Create model file at correct location
2. Include part directives for generated files
3. Add factory constructor for JSON
4. Add custom methods if needed
5. Run build_runner to generate code
6. Verify with `flutter analyze`
