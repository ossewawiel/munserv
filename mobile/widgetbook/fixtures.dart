import 'package:munserv_mobile/shared/models/geo_point.dart';
import 'package:munserv_mobile/shared/models/issue.dart';
import 'package:munserv_mobile/shared/models/issue_state.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/models/member.dart';

/// Fixture data shared across Widgetbook use-cases.
///
/// Kept outside `lib/` because it only exists for the catalogue.
class Fixtures {
  Fixtures._();

  static final DateTime referenceDate = DateTime(2026, 9, 1, 8, 30);

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
  }) {
    return IssueSummary(
      id: 'issue-1',
      type: type,
      state: state,
      location: location,
      heat: heat,
      thumbnailUrl: thumbnailUrl,
      createdAt: referenceDate,
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
