import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_type_icon.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/theme/issue_type_icons.dart';

void main() {
  group('IssueTypeIcon', () {
    testWidgets('renders icon with correct color for each type', (
      tester,
    ) async {
      for (final type in IssueType.values) {
        final visuals = IssueTypeVisuals.forType(type);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: IssueTypeIcon(type: type)),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(visuals.color));
        expect(icon.icon, equals(visuals.filledIcon));
      }
    });

    testWidgets('renders with default size of 56', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IssueTypeIcon(type: IssueType.pothole)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, equals(56));
      expect(constraints?.maxHeight, equals(56));
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIcon(type: IssueType.pothole, size: 80),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, equals(80));
      expect(constraints?.maxHeight, equals(80));
    });

    testWidgets('renders background container when showBackground is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIcon(
              type: IssueType.waterLeak,
              showBackground: true,
            ),
          ),
        ),
      );

      // Should find a container with decoration
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders only icon when showBackground is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIcon(
              type: IssueType.waterLeak,
              showBackground: false,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('uses filled icon by default', (tester) async {
      final visuals = IssueTypeVisuals.forType(IssueType.pothole);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IssueTypeIcon(type: IssueType.pothole)),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, equals(visuals.filledIcon));
    });

    testWidgets('uses outline icon when filled is false', (tester) async {
      final visuals = IssueTypeVisuals.forType(IssueType.pothole);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIcon(type: IssueType.pothole, filled: false),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, equals(visuals.icon));
    });

    testWidgets('has semantic label from visuals', (tester) async {
      final visuals = IssueTypeVisuals.forType(IssueType.pothole);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IssueTypeIcon(type: IssueType.pothole)),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.semanticLabel, equals(visuals.semanticLabel));
    });
  });

  group('IssueTypeIconCircle', () {
    testWidgets('renders circular icon for each type', (tester) async {
      for (final type in IssueType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: IssueTypeIconCircle(type: type)),
          ),
        );

        expect(find.byType(IssueTypeIconCircle), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      }
    });

    testWidgets('renders with default size of 40', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IssueTypeIconCircle(type: IssueType.pothole)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, equals(40));
      expect(constraints?.maxHeight, equals(40));
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIconCircle(type: IssueType.pothole, size: 60),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, equals(60));
      expect(constraints?.maxHeight, equals(60));
    });

    testWidgets('renders border by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIconCircle(
              type: IssueType.pothole,
              showBorder: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('renders without border when showBorder is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeIconCircle(
              type: IssueType.pothole,
              showBorder: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });
  });
}
