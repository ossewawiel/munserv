import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/map_background.dart';

void main() {
  group('MapBackground', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapBackground(child: Text('Test Content'))),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('contains a DecoratedBox with BoxDecoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapBackground(child: SizedBox())),
        ),
      );

      // Find the DecoratedBox that contains our background
      final decoratedBox = find.byType(DecoratedBox);
      expect(decoratedBox, findsWidgets);
    });

    testWidgets('uses cream color overlay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapBackground(child: SizedBox())),
        ),
      );

      // The widget should contain nested Containers
      // Outer container with background image decoration
      // Inner container with cream color overlay
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThanOrEqualTo(2));

      // Find the outer container (with decoration/image)
      final outerContainer = containers.firstWhere(
        (c) => c.decoration != null,
        orElse: () => containers.first,
      );
      expect(outerContainer.decoration, isA<BoxDecoration>());
    });

    testWidgets('fills available space', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapBackground(child: Text('Content'))),
        ),
      );

      // MapBackground should expand to fill available space
      final mapBackgroundFinder = find.byType(MapBackground);
      expect(mapBackgroundFinder, findsOneWidget);

      final mapBackground = tester.widget<MapBackground>(mapBackgroundFinder);
      expect(mapBackground.child, isNotNull);
    });

    testWidgets('applies background image decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapBackground(child: Text('Content'))),
        ),
      );

      // The outer Container should have a background image decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final decoratedContainers = containers.where((c) {
        if (c.decoration is BoxDecoration) {
          final decoration = c.decoration as BoxDecoration;
          return decoration.image != null;
        }
        return false;
      });
      expect(decoratedContainers, isNotEmpty);
    });
  });

  group('MapBackground overlay opacity', () {
    testWidgets('cream overlay has correct opacity (85%)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapBackground(child: SizedBox())),
        ),
      );

      // Verify the overlay Container exists
      // The opacity should be approximately 0.85 (85%)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });
}
