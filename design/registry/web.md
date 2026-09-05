# Web component registry

The catalogue of web building blocks, as agents must use them. Every entry has a story in Storybook (`pnpm --dir web storybook`); a new atom, molecule or organism is not done until it has one here and one there. Styling is the `sx` prop with theme tokens only; colours come from `web/src/theme/generated/tokens.ts`.

## Atoms (`src/components/atoms`)
| Component | Use when | Key props | Do / do not |
|---|---|---|---|
| `Button` | Any primary/secondary/danger/ghost action | `variant`, `isLoading`, MUI ButtonProps | Do use for every action button. Do not use raw MUI `Button` in features. |
| `ActionButton` | Soft-background action in toolbars and cards (Berry style) | `color`, `startIcon` | Do not stack more than two in a row. |
| `ActionIconButton` | Icon-only row action in tables | `aria-label` (required), `tooltip` | Do give it an accessible name. |
| `IconAvatar` | Icon in a coloured container (stat cards, lists) | `size` (`small`/`medium`/`large`), `color` | Sizes come from `avatarSizes`; do not pass pixel values. |
| `Badge` | Small status or count chip | `color`, `variant` | Use the semantic badges below for issue state, type and member status. |
| `Input`, `Select` | Form fields inside `react-hook-form` forms | `label`, `error`, `helperText` | Do not build ad-hoc `TextField`s in features. |
| `Modal` | Dialog shell | `open`, `onClose`, `title`, `actions` | Confirmations use `ConfirmDialog`, not `Modal` directly. |
| `MainCard` | Content card with optional title and actions (Berry) | `title`, `secondary`, `content` | The card for page sections; `Paper` only for custom layouts. |
| `Spinner` | Inline loading | `size` | Page-level loading uses `LoadingSkeleton`. |
| `ThemeToggle` | Light/dark/system switch | none | Header only. |
| `IssueTypeFilterButton` | One toggle in the issue type filter | `type`, `selected` | Only inside `IssueTypeFilterBar`. |

## Molecules (`src/components/molecules`)
| Component | Use when | Key props | Do / do not |
|---|---|---|---|
| `PageHeader`, `Breadcrumbs` | Top of every page | `title`, `actions`, breadcrumb items | Every page has exactly one `PageHeader`. |
| `StatCard` | A single figure with label and trend | `value`, `label`, `icon`, `color` | Dashboards only; use `IconAvatar` for the icon. |
| `IssueStateBadge`, `IssueTypeBadge`, `MemberStatusBadge` | Showing a domain state or type | `state` / `type` / `status` (wire value) | Colours come from `semanticIssueState` / `semanticIssueType` tokens; never restyle. |
| `HeatIndicator` | Heat 0 to 100 | `heat` | Levels from `getHeatLevel`; do not compute thresholds elsewhere. |
| `EmptyState`, `ErrorState`, `LoadingSkeleton` | Empty, error, loading content areas | `title`, `description`, `action`; `error`, `onRetry`; `variant` | Do not write inline empty or error markup. |
| `ConfirmDialog` | Any destructive or irreversible action | `title`, `message`, `confirmLabel`, `onConfirm`, `isLoading` | Confirm is `contained primary`, cancel is `outlined secondary`. |
| `Pagination` | Below any list not using `DataTableCard` | `page`, `pageSize`, `total`, `onChange` | Tables use `DataTableCard`'s built-in pagination. |
| `PhotoGallery`, `LocationPickerDialog` | Issue photos; picking a map point | `photos`; `value`, `onChange` | The only map picker; do not embed Leaflet directly in features. |
| `LoginForm`, `RegisterForm`, `IssueTypeFilterBar` | Their single purpose | see props | Feature-specific molecules; extend, do not duplicate. |

## Organisms and templates
| Component | Use when | Notes |
|---|---|---|
| `DataTableCard` (`organisms`) | Every admin list | Tabs, toolbar, pagination, URL-synced state. See the `web-data-table` skill. Never hand-roll a table. |
| `DataTable` | Only inside `DataTableCard` | Base table. |
| `NotificationDropdown`, `ProfileMenu`, `SessionExpiredHandler` | Header and session chrome | One instance each, in `DashboardLayout`. |
| `DashboardLayout`, `AuthLayout` (`templates`) | Page shells | Authenticated pages use `DashboardLayout`; login, register and onboarding use `AuthLayout`. `Sidebar` and `MiniDrawerStyled` belong to `DashboardLayout` only. |

## Theme
Light and dark schemes, semantic colours and layout sizes are generated into `src/theme/generated/tokens.ts` from `design/tokens/`. `createPodTheme` builds the MUI theme from a pod's brand colours; `ThemeContext` owns the colour mode. Do not hardcode a hex anywhere in `src/`.
