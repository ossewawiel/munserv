import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/theme/app_theme.dart';

class MunServApp extends ConsumerWidget {
  const MunServApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final podConfig = ref.watch(podConfigProvider);

    return MaterialApp.router(
      title: 'MunServ',
      debugShowCheckedModeBanner: false,

      // Theme configuration from pod
      theme: AppTheme.buildTheme(
        config: podConfig,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.buildTheme(
        config: podConfig,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,

      // Localization configuration
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,

      routerConfig: router,
    );
  }
}
