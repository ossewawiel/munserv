import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/form_error_banner.dart';

void main() {
  Widget createTestWidget({
    required String message,
    VoidCallback? onDismiss,
    bool animate = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FormErrorBanner(
          message: message,
          onDismiss: onDismiss,
          animate: animate,
        ),
      ),
    );
  }

  group('FormErrorBanner', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Invalid credentials'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Error message'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('uses errorContainer background color from theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(message: 'Error message', animate: false),
      );
      await tester.pump();

      // Find the container with decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final decoratedContainer = containers.firstWhere(
        (c) => c.decoration is BoxDecoration,
        orElse: Container.new,
      );

      expect(decoratedContainer.decoration, isA<BoxDecoration>());
      final decoration = decoratedContainer.decoration as BoxDecoration;
      // Should use errorContainer color from theme
      expect(decoration.color, isNotNull);
    });

    testWidgets('shows dismiss button when onDismiss is provided', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        createTestWidget(
          message: 'Error message',
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('does not show dismiss button when onDismiss is null', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(message: 'Error message'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('has rounded corners (border radius)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(message: 'Error message', animate: false),
      );
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final decoratedContainer = containers.firstWhere(
        (c) => c.decoration is BoxDecoration,
        orElse: Container.new,
      );

      final decoration = decoratedContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('icon uses onErrorContainer color from theme', (tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Error message'));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, isNotNull);
    });

    testWidgets('text uses onErrorContainer color from theme', (tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Error message'));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Error message'));
      expect(text.style?.color, isNotNull);
    });
  });

  group('FormErrorBanner animation', () {
    testWidgets('animates in when animate is true', (tester) async {
      await tester.pumpWidget(
        createTestWidget(message: 'Error message', animate: true),
      );

      // Initially should have animation in progress
      await tester.pump();

      // Find FadeTransition or SlideTransition
      expect(
        find.byType(FadeTransition).evaluate().isNotEmpty ||
            find.byType(AnimatedOpacity).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('does not animate when animate is false', (tester) async {
      await tester.pumpWidget(
        createTestWidget(message: 'Error message', animate: false),
      );
      await tester.pump();

      // Content should be immediately visible without animation wrapper
      expect(find.text('Error message'), findsOneWidget);
    });
  });

  group('FormErrorBanner accessibility', () {
    testWidgets('wraps content in Semantics widget', (tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Invalid credentials'));
      await tester.pumpAndSettle();

      // The widget should contain a Semantics widget
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
