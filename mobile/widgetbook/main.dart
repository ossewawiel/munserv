import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shared/theme/app_theme.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

/// Widgetbook catalogue for the mobile design system.
///
/// Run with `flutter run -t widgetbook/main.dart` or build for the web with
/// `flutter build web -t widgetbook/main.dart`. Every shared widget and
/// `IssueCard` variant in `design/registry/mobile.md` has a use-case here,
/// rendered with the app's real `AppTheme` in light and dark mode.
@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: AppTheme.lightTheme),
            WidgetbookTheme(name: 'Dark', data: AppTheme.darkTheme),
          ],
        ),
        // ignore: deprecated_member_use
        DeviceFrameAddon(
          devices: [Devices.ios.iPhone13, Devices.android.samsungGalaxyS20],
        ),
        TextScaleAddon(min: 0.8, max: 1.6),
      ],
      appBuilder: (context, child) {
        return ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Material(child: child),
          ),
        );
      },
    );
  }
}

void main() {
  runApp(const WidgetbookApp());
}
