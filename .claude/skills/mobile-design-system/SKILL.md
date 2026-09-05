---
name: mobile-design-system
description: The MunServ mobile design system - Material 3 tonal palette and brand colours, theme files, semantic colours, widget classification and the shared widget catalogue, IssueCard variants, EmptyState factories, sizing constants, the card and full-width standards, and the reuse rules. Load before creating or styling any mobile widget.
---

# Mobile design system

The core rules live in `mobile/CLAUDE.md`. This skill is the full catalogue. The Storybook-equivalent for Flutter (Widgetbook) replaces the debug theme showcase once the design-system PR lands.

## Material Design 3 Theming

The app uses Material Design 3 with a generated tonal palette system.

**Full spec:** [`/specs/Mobile_Theming_Guide.md`](/specs/Mobile_Theming_Guide.md)

### Brand Colors

| Role | Color | Hex |
|------|-------|-----|
| Primary | Forest Green | `#233D36` |
| Secondary | Terracotta | `#D9613F` |
| Tertiary | Warm Beige | `#F3EDDA` |

### Using Theme Colors

```dart
// ✅ DO: Use ColorScheme from theme
final colors = Theme.of(context).colorScheme;

colors.primary              // Primary actions
colors.primaryContainer     // FAB, prominent containers
colors.secondary            // Secondary actions
colors.secondaryContainer   // Selected nav items
colors.surfaceContainerLow  // Cards, dialogs
colors.surfaceContainerHigh // Menus, elevated surfaces
colors.onSurface            // Primary text
colors.onSurfaceVariant     // Secondary text

// ❌ DON'T: Hardcode colors
Container(color: Color(0xFF233D36))

// ❌ DON'T: Use .withOpacity() on theme colors
colors.primary.withOpacity(0.5) // Use semantic variant instead
```

### M3 Component Specifications

| Component | Height | Radius | Notes |
|-----------|--------|--------|-------|
| Buttons | 40dp | Stadium | 48dp touch target |
| Cards | - | 12dp | 1dp elevation |
| Nav Bar | 80dp | - | Pill indicator |
| FAB | 56dp | 16dp | primaryContainer |
| Chips | 32dp | 8dp | - |
| Inputs | - | 4dp | Filled style |
| Dialogs | - | 28dp | surfaceContainerHigh |

### Theme Files

| File | Purpose |
|------|---------|
| `shared/theme/colors.dart` | M3ColorSchemes, brand colors |
| `shared/theme/app_theme.dart` | ThemeData builder |
| `shared/theme/typography.dart` | TextTheme, Spacing, Radii, IconSizes, ThumbnailSizes |
| `shared/providers/theme_provider.dart` | Light/dark mode state |

### Semantic Colors

```dart
// Issue states
IssueStateColors.reported   // Orange
IssueStateColors.confirmed  // Blue
IssueStateColors.inProgress // Purple
IssueStateColors.fixed      // Green
IssueStateColors.rejected   // Gray

// Heat priority
HeatColors.fromHeat(75)     // Returns red for high heat
```

## Component Reusability Standards

**CRITICAL:** All UI components must be designed for reusability. Follow these standards.

### Widget Classification

| Type | Location | When to Use |
|------|----------|-------------|
| **Shared Widget** | `shared/widgets/` | Used by 2+ features OR represents core design system |
| **Feature Widget** | `features/{name}/presentation/widgets/` | Single feature, may become shared |
| **Private Widget** | Same file, `_` prefix | Single-use within one file only |

### Decision Tree: Where to Put a Widget?

```
Is it used by multiple features?
├─ YES → shared/widgets/
└─ NO → Is it a core UI pattern (card, badge, empty state)?
         ├─ YES → shared/widgets/ (anticipate reuse)
         └─ NO → features/{name}/presentation/widgets/
                 └─ Single-use in one file? → Keep private with _ prefix
```

### Shared Widgets (Design System Components)

These widgets form the app's design system and MUST be used consistently:

| Widget | File | Purpose | Usage |
|--------|------|---------|-------|
| `EmptyState` | `empty_state.dart` | Empty list/error states | Use factory constructors |
| `LoadingSpinner` | `loading_spinner.dart` | Loading indicators | Configurable size |
| `ErrorDisplay` | `error_display.dart` | Error states with retry | Always provide onRetry |
| `BrandedScaffold` | `branded_scaffold.dart` | Page wrapper with branding | All top-level pages |
| `QuickActionCard` | `quick_action_card.dart` | Tappable action cards | Home, dashboards |
| `StepIndicator` | `step_indicator.dart` | Wizard progress | Multi-step flows |

### IssueCard Variants

`IssueCard` supports variants for consistent issue display across the app:

```dart
enum IssueCardVariant {
  list,       // Full width, icon-based (default) - Issues list, My Reports, Home
  mapPreview, // Compact with thumbnail - Map bottom sheet
  compact,    // Minimal info - Constrained spaces
}

// Usage
IssueCard(
  issue: issue,
  variant: IssueCardVariant.list, // Default
  onTap: () => navigateToDetail(issue.id),
)

// Map preview with close button
IssueCard(
  issue: issue,
  variant: IssueCardVariant.mapPreview,
  onTap: () => navigateToDetail(issue.id),
  onClose: () => clearSelection(),
)
```

### EmptyState Factory Constructors

ALWAYS use the provided factory constructors instead of creating inline empty states:

```dart
// ✅ DO: Use factory constructors
EmptyState.noIssues(onRefresh: () => ref.invalidate(issuesProvider))
EmptyState.noReports(onReport: () => navigateToReport())
EmptyState.noResults(query: searchQuery)
EmptyState.networkError(onRetry: () => ref.invalidate(provider))
EmptyState.locationError(onRetry: () => requestLocationPermission())

// ❌ DON'T: Create inline empty state widgets
class _EmptyState extends StatelessWidget { ... } // FORBIDDEN
```

### Sizing Constants

ALWAYS use constants from `shared/theme/typography.dart`:

```dart
// ✅ DO: Use sizing constants
import 'package:munserv/shared/theme/typography.dart';

Icon(Icons.inbox, size: IconSizes.display)  // 80dp
Container(width: ThumbnailSizes.md)          // 64dp
SizedBox(height: Spacing.lg)                 // 24dp

// ❌ DON'T: Use magic numbers
Icon(Icons.inbox, size: 80)    // FORBIDDEN
Container(width: 64)            // FORBIDDEN
SizedBox(height: 24)            // FORBIDDEN
```

**Sizing Constants Reference:**

```dart
// Icon sizes
abstract class IconSizes {
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 24;   // Default icon size
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;  // Card icons
  static const double display = 80; // Empty states
}

// Thumbnail/image sizes
abstract class ThumbnailSizes {
  static const double sm = 48;
  static const double md = 64;   // Card thumbnails
  static const double lg = 100;  // Photo tiles
  static const double xl = 120;  // Large previews
}

// Spacing (already exists)
abstract class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

### Card Styling Standard

All cards MUST use consistent styling to match the app's visual design:

```dart
// ✅ DO: Use standard card styling
Card(
  elevation: 0,                              // No shadow or surface tint
  color: colors.surface,                     // Same as AppBar background
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    side: BorderSide(color: colors.outlineVariant),  // Visible border
  ),
  child: ...
)

// ❌ DON'T: Use default card styling
Card(child: ...)  // Has elevation tint, no border
Card(elevation: 1, child: ...)  // Has shadow/tint
Card(color: colors.tertiaryContainer, child: ...)  // Wrong background
```

**Card Styling Properties:**
| Property | Value | Reason |
|----------|-------|--------|
| `elevation` | `0` | Removes shadow and surface tint overlay |
| `color` | `colors.surface` | Matches AppBar header strip background |
| `shape.borderRadius` | `Radii.md` | Consistent rounded corners |
| `shape.side` | `colors.outlineVariant` | Distinct visible border |

This applies to:
- `IssueCard` (all variants)
- `QuickActionCard`
- Profile page cards (`_UserInfoCard`, `_SettingsItem`)
- Any new card widgets

### Full-Width Card Standard

All list item cards (especially `IssueCard`) MUST expand to full available width:

```dart
// ✅ DO: Cards fill available width
ListView.builder(
  itemBuilder: (context, index) => IssueCard(issue: issues[index]),
)

// IssueCard internally uses:
Card(
  margin: EdgeInsets.symmetric(
    horizontal: Spacing.md,
    vertical: Spacing.xs,
  ),
  elevation: 0,
  color: colors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    side: BorderSide(color: colors.outlineVariant),
  ),
  child: InkWell(
    // Content fills card width
  ),
)

// ❌ DON'T: Constrain card width
SizedBox(width: 300, child: IssueCard(...)) // FORBIDDEN
Center(child: IssueCard(...))                // FORBIDDEN
```

### Component Consistency Rules

1. **Same data = Same component** - Display the same data type with the same widget
2. **Variants over new widgets** - Add variants to existing widgets instead of creating new ones
3. **Shared over feature** - If unsure, put in `shared/widgets/` to encourage reuse
4. **Extract at 2 uses** - If you use something twice, extract to shared
5. **No inline states** - Empty, loading, error states use shared widgets

### Before Creating a Widget

Ask these questions:
1. Does a similar widget already exist in `shared/widgets/`?
2. Can I add a variant to an existing widget instead?
3. Will this be used in more than one place?
4. Does this represent a core UI pattern?

If YES to any → Use or extend existing shared widget
