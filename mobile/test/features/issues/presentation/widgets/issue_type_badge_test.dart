import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/issues/presentation/widgets/issue_type_badge.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/theme/issue_type_icons.dart';

void main() {
  group('IssueTypeBadge', () {
    testWidgets('displays type name and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IssueTypeBadge(type: IssueType.pothole)),
        ),
      );

      expect(find.text('Pothole'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssueTypeBadge(type: IssueType.pothole, showLabel: false),
          ),
        ),
      );

      expect(find.text('Pothole'), findsNothing);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('displays correct icon for each type', (tester) async {
      for (final type in IssueType.values) {
        final visuals = IssueTypeVisuals.forType(type);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: IssueTypeBadge(type: type)),
          ),
        );

        expect(find.byIcon(visuals.filledIcon), findsOneWidget);
      }
    });

    testWidgets('displays correct label for each type', (tester) async {
      for (final type in IssueType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: IssueTypeBadge(type: type)),
          ),
        );

        expect(find.text(type.displayName), findsOneWidget);
      }
    });
  });
}
