import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/app_logo.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Sizes', type: AppLogo)
Widget appLogo(BuildContext context) {
  final size = context.knobs.object.dropdown<AppLogoSize>(
    label: 'Size',
    options: AppLogoSize.values,
    labelBuilder: (value) => value.name,
  );

  return AppLogo(size: size);
}
