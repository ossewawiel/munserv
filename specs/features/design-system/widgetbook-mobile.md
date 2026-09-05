---
issue: 0
story: DS2
title: "Widgetbook catalogue for the mobile design system"
platform: mobile
status: completed
depends_on: []
touches: [design-system, mobile-shared-widgets]
created_by: orchestrator
created_at: "2026-09-05"
files_changed:
  - mobile/pubspec.yaml
  - mobile/pubspec.lock
  - mobile/build.yaml
  - mobile/analysis_options.yaml
  - mobile/README.md
  - mobile/CLAUDE.md
  - mobile/web/** (flutter create . --platforms web)
  - mobile/widgetbook/main.dart
  - mobile/widgetbook/main.directories.g.dart
  - mobile/widgetbook/fixtures.dart
  - mobile/widgetbook/use_cases/app_logo.dart
  - mobile/widgetbook/use_cases/branded_scaffold.dart
  - mobile/widgetbook/use_cases/branding_header.dart
  - mobile/widgetbook/use_cases/design_tokens.dart
  - mobile/widgetbook/use_cases/empty_state.dart
  - mobile/widgetbook/use_cases/error_display.dart
  - mobile/widgetbook/use_cases/form_error_banner.dart
  - mobile/widgetbook/use_cases/heat_indicator.dart
  - mobile/widgetbook/use_cases/issue_card.dart
  - mobile/widgetbook/use_cases/issue_location_map.dart
  - mobile/widgetbook/use_cases/issue_type_icon.dart
  - mobile/widgetbook/use_cases/loading_spinner.dart
  - mobile/widgetbook/use_cases/map_background.dart
  - mobile/widgetbook/use_cases/munserv_app_bar.dart
  - mobile/widgetbook/use_cases/photo_thumbnail_carousel.dart
  - mobile/widgetbook/use_cases/quick_action_card.dart
  - mobile/widgetbook/use_cases/step_indicator.dart
  - mobile/lib/features/dev/presentation/pages/theme_showcase_page.dart (removed)
  - mobile/lib/features/profile/presentation/pages/profile_page.dart
  - mobile/lib/routing/app_router.dart
  - mobile/lib/routing/app_router.g.dart (regenerated hash)
  - mobile/lib/features/auth/providers/auth_providers.g.dart (regenerated hash)
  - mobile/lib/shared/providers/dio_provider.g.dart (regenerated hash)
  - mobile/lib/shared/theme/generated/tokens.dart (trailing newline only)
tests_added: []
---

# DS2 · Widgetbook catalogue (Mobile)

Read `design/README.md` and `design/registry/mobile.md`. This handoff is complete on its own.

## Outcome
`flutter run -t widgetbook/main.dart` (and `flutter build web -t widgetbook/main.dart`) opens a Widgetbook with every shared widget and `IssueCard` variant in the registry, rendered with the real `AppTheme` in light and dark mode. The debug-only theme showcase page is gone; Widgetbook replaces it.

## Acceptance criteria
- [ ] `widgetbook` 3.25, `widgetbook_annotation` 3.11 and `widgetbook_generator` 3.24 added to `mobile/pubspec.yaml` (annotation in `dependencies`, generator in `dev_dependencies`); `build_runner` generates `widgetbook/main.directories.g.dart`
- [ ] `mobile/widgetbook/main.dart` runs a `Widgetbook.material` app with the project's light and dark `ThemeData` from `lib/shared/theme/app_theme.dart`, device frames, and a text-scale knob
- [ ] One `@UseCase` per widget in `design/registry/mobile.md` (shared widgets, `IssueCard` in all three variants, `HeatIndicator` at 0, 25, 50, 75, 100, `IssueTypeIcon` per type, `EmptyState` per factory), with knobs for the meaningful parameters
- [ ] A `Design/Tokens` use-case rendering the generated colour classes and size scales from `lib/shared/theme/generated/tokens.dart`
- [ ] `lib/features/dev/presentation/pages/theme_showcase_page.dart` and its route, tests and navigation entry removed; nothing else in `features/dev` is removed unless it only served the showcase
- [ ] `dart format`, `flutter analyze --fatal-infos`, `flutter test` pass; `flutter build web -t widgetbook/main.dart` succeeds and its output is gitignored

## Contract
None. No widget behaviour changes.

## Steps
1. `mobile/pubspec.yaml`: add the three packages at the versions above; `flutter pub get`. If `widgetbook_generator` conflicts with `riverpod_generator` / `freezed`, resolve versions and report which.
2. `mobile/widgetbook/main.dart` and `mobile/widgetbook/main.directories.g.dart` (generated): `@App()` with `Widgetbook.material(directories: directories, addons: [MaterialThemeAddon(light/dark from AppTheme), DeviceFrameAddon, TextScaleAddon])`. Riverpod: wrap in `ProviderScope` with any providers the widgets read overridden to fixtures.
3. Use-cases in `mobile/widgetbook/use_cases/<widget>.dart` (not inside `lib/`), one file per registry row, `@UseCase(name:, type:)`. Fixture data in `mobile/widgetbook/fixtures.dart` (a sample `Issue`, `Member`, photos as `NetworkImage` placeholders or asset images already in `assets/`).
4. `dart run build_runner build --delete-conflicting-outputs`; commit the generated directories file.
5. Remove the theme showcase page, its route in `lib/routing/app_router.dart`, its entry point in the profile or dev menu, and its tests. Grep for `ThemeShowcasePage` / `theme_showcase` to find every reference.
6. `.gitignore`: nothing new is needed for `flutter build web` output under `build/` (already ignored); confirm.
7. `mobile/README.md`: add a "Widgetbook" section with the two commands. `mobile/CLAUDE.md`: in the reuse rule, replace "a new shared widget needs a Widgetbook use-case once it exists" wording if present with the definitive rule.

## Do not
- Do not change any widget's API or styling to make a use-case easier; if a widget needs a real provider, override it in the `ProviderScope`.
- Do not add Widgetbook Cloud or any paid service.
- Do not touch `web/`, `backend/`, `design/tokens/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
cd mobile && dart format --set-exit-if-changed lib test widgetbook && flutter analyze --fatal-infos && flutter test && flutter build web -t widgetbook/main.dart
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with the use-case count and anything skipped. If you cannot finish, set `status: blocked` and end your message with `BLOCKED: <reason>`.
