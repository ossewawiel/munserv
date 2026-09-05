# Mobile widget registry

The catalogue of shared widgets, as agents must use them. Every shared widget has a Widgetbook use-case (`flutter run -t widgetbook/main.dart` in `mobile/`); a new shared widget is not done until it has one here and one there. Colours come from `Theme.of(context).colorScheme` and `lib/shared/theme/generated/tokens.dart`; sizes from `Spacing`, `Radii`, `IconSizes`, `ThumbnailSizes`.

## Shared widgets (`lib/shared/widgets`)
| Widget | Use when | Key parameters | Do / do not |
|---|---|---|---|
| `BrandedScaffold` | Every top-level page | `title`, `body`, `actions`, `floatingActionButton` | Do not use a bare `Scaffold` for a page. |
| `MunservAppBar`, `BrandingHeader`, `AppLogo` | App bar and branding | `title`; `size` (`AppLogoSize`) | Part of `BrandedScaffold`; use directly only in auth pages. |
| `EmptyState` | Empty lists, no results, network or location errors | factory constructors: `noIssues`, `noReports`, `noResults`, `networkError`, `locationError` | Always a factory; never an inline `_EmptyState` class. |
| `LoadingSpinner` | Loading content | `size` | Use inside `AsyncValue.when(loading:)`. |
| `ErrorDisplay` | Error content with retry | `error`, `onRetry` (always provide) | Use inside `AsyncValue.when(error:)`. |
| `FormErrorBanner` | Validation or submit error above a form | `message` | One per form, top of the form. |
| `QuickActionCard` | Tappable action tile on Home and dashboards | `icon`, `title`, `subtitle`, `onTap` | Standard card styling applies. |
| `StepIndicator` | Multi-step flows (registration, report issue) | `currentStep`, `totalSteps`, `labels` | Do not draw dots by hand. |
| `PhotoThumbnailCarousel` | Row of issue photos | `photos`, `onTap`, size from `ThumbnailSizes` | Thumbnails only; full view is the gallery page. |
| `IssueLocationMap`, `MapBackground` | Small map preview; decorative map backdrop | `location`; none | The full map is `IssueMapPage`. |

## Feature widgets that behave as shared
| Widget | Location | Variants |
|---|---|---|
| `IssueCard` | `features/issues/presentation/widgets` | `IssueCardVariant.list` (default), `mapPreview` (with `onClose`), `compact` |
| `HeatIndicator`, `IssueTypeIcon` | same | Colours from `HeatColors` / `IssueTypeIcons`, which read the generated tokens |

## Standards
- Cards: `elevation: 0`, `color: colors.surface`, `Radii.md`, `colors.outlineVariant` border, full width in lists.
- Same data, same widget; add a variant before adding a widget; extract at the second use; single-use helpers are `_Private` in the same file.
- Dark scheme: mobile's `M3ColorSchemes.dark` differs from the web dark tokens on 13 roles; tracked in the design issue opened with PR 5a. Do not "fix" it in a feature story.
