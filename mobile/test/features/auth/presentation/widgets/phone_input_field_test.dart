import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/phone_input_field.dart';

void main() {
  group('PhoneInputField', () {
    testWidgets('renders with country code prefix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              countryCode: '+27',
            ),
          ),
        ),
      );

      expect(find.text('+27'), findsOneWidget);
    });

    testWidgets('uses custom country code', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              countryCode: '+1',
            ),
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('formats phone number with spaces', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              controller: controller,
            ),
          ),
        ),
      );

      // Find the text field and enter digits
      final textField = find.byType(TextField);
      await tester.enterText(textField, '821234567');
      await tester.pump();

      // Should be formatted as "82 123 4567"
      expect(controller.text, '82 123 4567');
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              errorText: 'Invalid phone number',
            ),
          ),
        ),
      );

      expect(find.text('Invalid phone number'), findsOneWidget);
    });

    testWidgets('calls onChanged with full phone number', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              countryCode: '+27',
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, '821234567');
      await tester.pump();

      expect(changedValue, '+27821234567');
    });

    testWidgets('respects enabled state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });
  });
}
