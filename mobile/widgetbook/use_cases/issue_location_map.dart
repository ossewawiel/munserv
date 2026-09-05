import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/issue_location_map.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../fixtures.dart';

@widgetbook.UseCase(name: 'Default', type: IssueLocationMap)
Widget issueLocationMap(BuildContext context) {
  return IssueLocationMap(
    latitude: Fixtures.location.latitude,
    longitude: Fixtures.location.longitude,
    onTap: () {},
  );
}
