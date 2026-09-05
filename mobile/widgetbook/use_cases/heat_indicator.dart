import 'package:flutter/material.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/heat_indicator.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Heat 0', type: HeatIndicator)
Widget heatIndicator0(BuildContext context) => const HeatIndicator(heat: 0);

@widgetbook.UseCase(name: 'Heat 25', type: HeatIndicator)
Widget heatIndicator25(BuildContext context) => const HeatIndicator(heat: 25);

@widgetbook.UseCase(name: 'Heat 50', type: HeatIndicator)
Widget heatIndicator50(BuildContext context) => const HeatIndicator(heat: 50);

@widgetbook.UseCase(name: 'Heat 75', type: HeatIndicator)
Widget heatIndicator75(BuildContext context) => const HeatIndicator(heat: 75);

@widgetbook.UseCase(name: 'Heat 100', type: HeatIndicator)
Widget heatIndicator100(BuildContext context) => const HeatIndicator(heat: 100);
