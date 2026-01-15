import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/heat_indicator.dart';

void main() {
  group('HeatIndicator', () {
    testWidgets('displays heat value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HeatIndicator(heat: 75))),
      );

      expect(find.text('75'), findsOneWidget);
      expect(find.text('Heat'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeatIndicator(heat: 75, showLabel: false)),
        ),
      );

      expect(find.text('75'), findsOneWidget);
      expect(find.text('Heat'), findsNothing);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeatIndicator(heat: 50, size: 60)),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 60);
      expect(sizedBox.height, 60);
    });

    testWidgets('clamps heat to 0-100 range', (tester) async {
      // Test with value over 100
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HeatIndicator(heat: 150))),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      // Value should be clamped to 1.0 (100/100)
      expect(progressIndicator.value, 1.0);
    });
  });

  group('HeatBadge', () {
    testWidgets('displays heat value with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HeatBadge(heat: 65))),
      );

      expect(find.text('65'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('renders for different heat levels', (tester) async {
      for (final heat in [10, 45, 65, 85]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: HeatBadge(heat: heat)),
          ),
        );

        expect(find.text(heat.toString()), findsOneWidget);
      }
    });
  });
}
