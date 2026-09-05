import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/map_background.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: MapBackground)
Widget mapBackground(BuildContext context) {
  final overlayOpacity = context.knobs.double.slider(
    label: 'Overlay opacity',
    initialValue: 0.90,
    min: 0,
    max: 1,
  );

  return MapBackground(
    overlayOpacity: overlayOpacity,
    child: const Center(child: Text('Content over the map background')),
  );
}
