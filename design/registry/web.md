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
| `FeedbackSnackbar` (`organisms`) | Every transient outcome: saved, revoked, sent, deleted | Bottom-centre `Snackbar` + filled `Alert`, 4s auto-hide, one at a time. Driven by a `useFeedback` hook so a page never renders its own `Snackbar`. See **Feedback** below. |
| `SupportGrantBanner` | Header, only while the signed-in user holds an active support grant | Renders `null` with no stored grant. Counts down to the grant's server-owned, sliding `expires_at`; refreshes on route change and once at zero, never on a timer (see `domain/support-grant.md`). |
| `DashboardLayout`, `AuthLayout` (`templates`) | Page shells | Authenticated pages use `DashboardLayout`; login, register and onboarding use `AuthLayout`. `Sidebar` and `MiniDrawerStyled` belong to `DashboardLayout` only. |

## Feedback

Two kinds of message, and the kind decides the container. Getting this wrong is what #128 was raised for.

**Transient outcome — it worked.** Saved, revoked, sent, resent, deleted, copied. Use `FeedbackSnackbar`: a bottom-centre MUI `Snackbar` (`anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}`) holding an `Alert` with `variant="filled"` and the matching `severity` (`success`, `info`, `warning`), `autoHideDuration={4000}`, `elevation={6}`. One at a time — a second outcome replaces the first, it never stacks. The bar floats over the page, so nothing reflows when it arrives or leaves, and the card the user just acted on keeps its layout.

**Persistent problem — the user has to do something.** Field validation stays on the field (`Input` `error` + `helperText`). A rejection the user must read and act on — a 400 from the server, a conflict, a permission refusal — stays as an inline `Alert` at the top of the form or card it belongs to, with no auto-hide and no snackbar. Never announce a failed save in a bar that disappears after four seconds.

Rules:
- Never hand-roll a `Snackbar` in a feature. `FeedbackSnackbar` is mounted once in `DashboardLayout`; features call the `useFeedback` hook (`showFeedback({ message, severity })`) from the mutation's `onSuccess`.
- The message is always a translated key. No English string literal reaches the bar.
- `severity="error"` in the bar is for outcomes the user cannot act on and does not need to retry from a form (a background refresh that failed, for instance). Anything a form owns is inline.
- `SessionExpiredHandler` is the one deliberate exception: a top-centre warning bar with a redirect behind it, not a form outcome. Do not fold it into `FeedbackSnackbar`.

**Undoing an edit.** A form that can be edited in place carries `Reset` beside its primary action — `Button` `variant="secondary"` (outlined), 12px to the left of the save button, enabled only while the form is dirty and disabled while the mutation is in flight. It restores the last saved values from the query and clears field errors (`reset()` from `react-hook-form`); it is not a page reload. Drawn on the Pod Settings canvas, artboard `IdentityDirty`.

## Theme
Light and dark schemes, semantic colours and layout sizes are generated into `src/theme/generated/tokens.ts` from `design/tokens/`. `createPodTheme` builds the MUI theme from a pod's brand colours; `ThemeContext` owns the colour mode. Do not hardcode a hex anywhere in `src/`.
