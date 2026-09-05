import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/branding_header.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: BrandingHeader)
Widget brandingHeader(BuildContext context) {
  return const BrandingHeader();
}
