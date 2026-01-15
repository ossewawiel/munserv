import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/loading_button.dart';

void main() {
  group('LoadingButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(label: 'Continue', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Continue',
              onPressed: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(wasTapped, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Continue',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('is disabled when isLoading is true', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Continue',
              onPressed: () {
                wasTapped = true;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(wasTapped, false);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Continue',
              onPressed: () {
                wasTapped = true;
              },
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(wasTapped, false);
    });

    testWidgets('expands to full width when expand is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Continue',
              onPressed: () {},
              expand: true,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });
  });

  group('LoadingOutlinedButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingOutlinedButton(label: 'Cancel', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingOutlinedButton(
              label: 'Cancel',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });
  });
}
