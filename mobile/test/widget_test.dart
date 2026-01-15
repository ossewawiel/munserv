import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munserv_mobile/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MunServApp()));

    // Pump a few frames to allow initial rendering
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the app renders without crashing
    expect(find.byType(MunServApp), findsOneWidget);
  });
}
