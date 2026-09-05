# Mobile card - Flutter 3.47 + Riverpod 3 + Freezed 4 + Material 3

Read `domain/README.md` first. Load `mobile-design-system` before touching any widget, `mobile-patterns` for worked examples of models, providers, repositories and tests. Theming detail: `specs/Mobile_Theming_Guide.md`.

## Layers
`Presentation (pages, widgets)` → `Providers (Riverpod)` → `Repository` → `API (Dio)`. Folder: `lib/features/<name>/{data,domain,providers,presentation}`, `lib/shared/{models,widgets,providers,theme,utils}`, `lib/shell` (4-tab navigation), `lib/routing` (go_router). Members are the only mobile users; there is no admin UI here.

## The rules that get broken
1. **State is Riverpod.** `@riverpod` providers and notifiers (generated, `Ref ref`); `AsyncValue.when` in widgets; no `setState` for shared state, no `FutureBuilder`, no error handling in widgets.
2. **Models are Freezed** with a private constructor for behaviour and `fromJson`; enums carry `displayName` and, for lifecycles, `allowedTransitions`. Wire values are snake_case strings matching `domain/language.yaml`.
3. **Errors are `Result<T>`** (`Success` / `Failure(AppError)`) from repositories; providers turn `Failure` into `AsyncError`.
4. **Theme tokens only**: `Theme.of(context).colorScheme.*`; sizes from `Spacing`, `IconSizes`, `ThumbnailSizes`, `Radii` in `shared/theme/typography.dart`. No literal colours, no magic numbers, no `.withOpacity` on theme colours.
5. **Reuse before create**: `shared/widgets/` (`EmptyState` factories, `LoadingSpinner`, `ErrorDisplay`, `BrandedScaffold`, `QuickActionCard`, `StepIndicator`, `IssueCard` with `list` / `mapPreview` / `compact` variants) is the design system. Same data, same widget; add a variant rather than a new widget; extract at the second use; private single-use widgets are `_Prefixed` in the same file. A new shared widget is not done until it has a row in `design/registry/mobile.md` and a use-case in `mobile/widgetbook/use_cases/`.
6. **Cards**: `elevation: 0`, `color: colors.surface`, `Radii.md` corners, `colors.outlineVariant` border, full width in lists.

## Configuration
API host and port via `--dart-define=API_HOST=... --dart-define=API_PORT=...` (defaults `10.0.2.2:8080`, the Android emulator's route to the host). Secure storage holds session and PIN; biometric login is optional after PIN setup.

## Tests
flutter_test + Mocktail; `ProviderContainer` with overrides for provider tests; widget tests wrap in `ProviderScope`. Test files mirror `lib/` under `test/`. No integration_test yet; golden tests arrive with the design-system PR.

## Commands
```bash
dart run build_runner build --delete-conflicting-outputs   # after model/provider changes
dart format lib test && flutter analyze --fatal-infos       # CI runs both
flutter test                                                # 375 tests
flutter build apk --debug                                   # CI smoke build
flutter run                                                 # device or emulator
```

## Forbidden
`dynamic`; `setState` for shared state; `late` outside controllers and animations; `FutureBuilder` / `StreamBuilder`; business logic in widgets; nesting deeper than four widgets without extraction; `print` (use `dart:developer` `log`); inline empty, loading or error states; a widget that duplicates a shared one; a new enum value that is not also in the backend, web and `domain/`.

## Skills
`/dev-cycle`, `/fix-issue`, `/feature`, `/screen`, `/widget`, `/shared-widget`, `/provider`, `/repository`, `/model`, `/test`, `/widget-test`, `/integration-test`, `/review-code`, `/ci-fix` in `mobile/.claude/commands/`.
