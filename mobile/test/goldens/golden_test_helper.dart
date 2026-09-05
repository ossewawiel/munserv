import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shared/theme/app_theme.dart';

/// Full-screen golden surface, matching a small modern phone (iPhone 13
/// mini logical resolution) so `BrandedScaffold` / `MunServAppBar` render a
/// realistic layout.
const Size kGoldenPhoneSize = Size(390, 844);

/// Golden surface sized for a single widget rather than a full screen.
const Size kGoldenWidgetSize = Size(360, 240);

/// Font strategy: `google_fonts` normally downloads font files over the
/// network on first use. That is both slow and non-deterministic in tests,
/// so runtime fetching is disabled here (see [goldenTestSetUp]). With
/// fetching disabled and no bundled `.ttf` assets, `GoogleFonts.sourceSans3`
/// falls back to the platform default text style. That fallback is
/// deterministic — it depends on neither the network nor the machine — so
/// it renders identically on a developer's Linux machine and on the Linux
/// CI runner, which is all a golden test needs.
///
/// Call once per test file, inside `setUpAll`.
void goldenTestSetUp() {
  GoogleFonts.config.allowRuntimeFetching = false;
  debugDisableShadows = true;
}

/// Pumps [widget] inside a [ProviderScope] and a [MaterialApp] configured
/// with the app's real light/dark theme and localizations, at a fixed
/// surface size, then settles.
///
/// Use [dark] to pick [AppTheme.darkTheme] instead of [AppTheme.lightTheme].
/// Use [size] to control the golden surface; defaults to
/// [kGoldenWidgetSize]. Pass [overrides] for widgets that read providers.
///
/// Set [settle] to `false` for widgets with an indeterminate (infinite)
/// animation, such as an unbounded [CircularProgressIndicator] — a single
/// [WidgetTester.pump] is deterministic (the fake test clock does not
/// advance), whereas [WidgetTester.pumpAndSettle] would time out waiting
/// for an animation that never stops.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget widget, {
  bool dark = false,
  Size size = kGoldenWidgetSize,
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        // A Scaffold gives every widget a Material ancestor (InkWell, Card
        // splash, etc.) without changing widgets that already bring their
        // own Scaffold (e.g. BrandedScaffold nests fine).
        home: Scaffold(body: widget),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
