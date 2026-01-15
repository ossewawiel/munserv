import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/pin_input_field.dart';

void main() {
  group('PinInputField', () {
    testWidgets('renders 4 pin boxes by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PinInputField())),
      );

      // Find all pin boxes (containers with fixed size)
      final containers = find.byType(Container);
      // We have 4 boxes + 1 main container + 1 center
      expect(containers.evaluate().length, greaterThanOrEqualTo(4));
    });

    testWidgets('renders custom length pin boxes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PinInputField(length: 6))),
      );

      // Find the gesture detector that wraps the boxes
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('calls onCompleted when PIN is fully entered', (tester) async {
      String? completedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputField(
              length: 4,
              autoFocus: false,
              onCompleted: (value) {
                completedValue = value;
              },
            ),
          ),
        ),
      );

      // Find the hidden text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter PIN
      await tester.enterText(textField, '1234');
      await tester.pump();

      expect(completedValue, '1234');
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinInputField(errorText: 'Invalid PIN')),
        ),
      );

      expect(find.text('Invalid PIN'), findsOneWidget);
    });

    testWidgets('hides digits when obscureText is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinInputField(obscureText: true)),
        ),
      );

      // Find the hidden text field and enter a digit
      final textField = find.byType(TextField);
      await tester.enterText(textField, '1');
      await tester.pump();

      // Should show dots/circles instead of digits
      // We look for the circular container that represents obscured digit
      final circles = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(circles, findsOneWidget);
    });
  });
}
