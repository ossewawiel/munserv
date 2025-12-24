import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/otp_input_field.dart';

void main() {
  group('OtpInputField', () {
    testWidgets('renders 6 input fields by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              onCompleted: (_) {},
            ),
          ),
        ),
      );

      // Find all TextFields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));
    });

    testWidgets('renders custom length input fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              length: 4,
              onCompleted: (_) {},
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));
    });

    testWidgets('calls onCompleted when all fields are filled', (tester) async {
      String? completedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              length: 4,
              autoFocus: false,
              onCompleted: (value) {
                completedValue = value;
              },
            ),
          ),
        ),
      );

      // Enter digits one by one
      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(0), '1');
      await tester.pump();
      await tester.enterText(textFields.at(1), '2');
      await tester.pump();
      await tester.enterText(textFields.at(2), '3');
      await tester.pump();
      await tester.enterText(textFields.at(3), '4');
      await tester.pump();

      expect(completedValue, '1234');
    });

    testWidgets('only accepts digits', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              length: 4,
              autoFocus: false,
              onCompleted: (_) {},
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);

      // Try to enter a letter
      await tester.enterText(textFields.at(0), 'a');
      await tester.pump();

      // The field should be empty (letter filtered out)
      final textField = tester.widget<TextField>(textFields.at(0));
      expect(textField.controller?.text, '');
    });

    testWidgets('respects enabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              enabled: false,
              onCompleted: (_) {},
            ),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      final textField = tester.widget<TextField>(textFields.at(0));

      expect(textField.enabled, false);
    });
  });
}
