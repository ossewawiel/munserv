import 'package:flutter/material.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_type_icon.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Pothole', type: IssueTypeIcon)
Widget issueTypeIconPothole(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.pothole);

@widgetbook.UseCase(name: 'Water leak', type: IssueTypeIcon)
Widget issueTypeIconWaterLeak(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.waterLeak);

@widgetbook.UseCase(name: 'Sewage leak', type: IssueTypeIcon)
Widget issueTypeIconSewageLeak(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.sewageLeak);

@widgetbook.UseCase(name: 'Traffic light', type: IssueTypeIcon)
Widget issueTypeIconTrafficLight(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.trafficLight);

@widgetbook.UseCase(name: 'Street light', type: IssueTypeIcon)
Widget issueTypeIconStreetLight(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.streetLight);

@widgetbook.UseCase(name: 'Illegal dumping', type: IssueTypeIcon)
Widget issueTypeIconIllegalDumping(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.illegalDumping);

@widgetbook.UseCase(name: 'Road damage', type: IssueTypeIcon)
Widget issueTypeIconRoadDamage(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.roadDamage);

@widgetbook.UseCase(name: 'Other', type: IssueTypeIcon)
Widget issueTypeIconOther(BuildContext context) =>
    const IssueTypeIcon(type: IssueType.other);
