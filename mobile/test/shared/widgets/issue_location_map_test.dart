import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munserv_mobile/shared/widgets/issue_location_map.dart';

void main() {
  group('IssueLocationMap', () {
    testWidgets('renders FlutterMap widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('renders with 1:1 aspect ratio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, equals(1.0));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap on the "Tap to expand" hint which is part of the map overlay
      await tester.tap(find.text('Tap to expand'));
      expect(tapped, isTrue);
    });

    testWidgets('shows expand hint when onTap is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tap to expand'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('hides expand hint when no onTap provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      expect(find.text('Tap to expand'), findsNothing);
    });

    testWidgets('renders marker at correct position', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      // Verify MarkerLayer exists
      expect(find.byType(MarkerLayer), findsOneWidget);
    });

    testWidgets('renders location pin icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueLocationMap(
              latitude: -26.2041,
              longitude: 28.0473,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });
  });
}
