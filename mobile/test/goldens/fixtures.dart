import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/models/member.dart';

/// Fixture data shared across the Widgetbook catalogue and the golden tests.
///
/// Lives under `test/` (not `widgetbook/`) because the golden suite needs a
/// deterministic [referenceDate]: far enough in the past that
/// `IssueCard`'s relative-date formatting ("Just now" / "3d ago" / ...)
/// always resolves to the fixed `d/m/yyyy` branch, regardless of which day
/// the suite runs on. `widgetbook/fixtures.dart` re-exports this file so the
/// catalogue and the goldens never drift apart.
class Fixtures {
  Fixtures._();

  /// Deliberately old: keeps `IssueCard`'s "N days ago" formatting stable
  /// (falls into the fixed date branch) no matter when tests run.
  static final DateTime referenceDate = DateTime(2020, 1, 15, 8, 30);

  static final GeoPoint location = const GeoPoint(
    latitude: -26.1234,
    longitude: 28.1234,
  );

  /// A single [IssueSummary] used as the default for card use-cases.
  static IssueSummary issueSummary({
    IssueType type = IssueType.pothole,
    IssueState state = IssueState.reported,
    int heat = 45,
    String? thumbnailUrl =
        'https://placehold.co/200x200/233D36/FFFFFF.png?text=Photo',
    DateTime? createdAt,
  }) {
    return IssueSummary(
      id: 'issue-1',
      type: type,
      state: state,
      location: location,
      heat: heat,
      thumbnailUrl: thumbnailUrl,
      createdAt: createdAt ?? referenceDate,
    );
  }

  /// A full [Issue] with photos, used where a detailed model is needed.
  static Issue issue({
    IssueType type = IssueType.pothole,
    IssueState state = IssueState.reported,
    int heat = 45,
  }) {
    return Issue(
      id: 'issue-1',
      type: type,
      state: state,
      location: location,
      address: '12 Voortrekker Street, Northcliff',
      description: 'Deep pothole blocking half the lane after the rains.',
      heat: heat,
      photoUrls: photoUrls,
      sectorId: 'sector-1',
      reporterId: 'member-1',
      reportCount: 3,
      createdAt: referenceDate,
      updatedAt: referenceDate,
    );
  }

  static const List<String> photoUrls = [
    'https://placehold.co/400x400/233D36/FFFFFF.png?text=Photo+1',
    'https://placehold.co/400x400/D9613F/FFFFFF.png?text=Photo+2',
    'https://placehold.co/400x400/F3EDDA/233D36.png?text=Photo+3',
  ];

  static final Member member = Member(
    id: 'member-1',
    firstName: 'Thandiwe',
    surname: 'Nkosi',
    phoneNumber: '+27821234567',
    address: '12 Voortrekker Street, Northcliff',
    registrationLocation: location,
    sectorId: 'sector-1',
    status: MemberStatus.active,
    createdAt: referenceDate,
  );
}
