# Mobile Theming Guide

Material Design 3 theming specification for the MunServ mobile app.

## 1. Color System

### 1.1 Brand Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary | Forest Green | `#233D36` | Primary actions, key UI elements |
| Secondary | Terracotta | `#D9613F` | Secondary actions, accents, CTAs |
| Tertiary | Warm Beige | `#F3EDDA` | Backgrounds, tertiary elements |

### 1.2 M3 Color Roles

The app uses Material Design 3's tonal palette system generated from the brand colors. All 36 color roles are defined in `M3ColorSchemes` class.

#### Primary Tonal Palette (Forest Green)
```
primary:              #0c2721  - Primary actions, prominent buttons
onPrimary:            #ffffff  - Text/icons on primary
primaryContainer:     #233d36  - Less prominent containers
onPrimaryContainer:   #8ba89e  - Text on primary container
```

#### Secondary Tonal Palette (Terracotta)
```
secondary:            #a2391a  - Secondary actions
onSecondary:          #ffffff  - Text/icons on secondary
secondaryContainer:   #c35130  - Nav indicators, selected states
onSecondaryContainer: #fffbff  - Text on secondary container
```

#### Tertiary Tonal Palette (Beige)
```
tertiary:             #615f50  - Tertiary accents
onTertiary:           #ffffff  - Text/icons on tertiary
tertiaryContainer:    #f1edda  - Tertiary backgrounds
onTertiaryContainer:  #6d6b5c  - Text on tertiary container
```

#### Surface Colors (M3 Elevation System)
```
surface:                  #faf9f7  - Default surface, Cards, AppBar
surfaceContainerLowest:   #ffffff  - Lowest elevation
surfaceContainerLow:      #f4f3f2  - Elevated surfaces
surfaceContainer:         #efeeec  - Navigation bars
surfaceContainerHigh:     #e9e8e6  - Dialogs, menus
surfaceContainerHighest:  #e3e2e1  - Inputs, active states
```

#### Semantic Colors
```
error:          #ba1a1a  - Error states
errorContainer: #ffdad6  - Error backgrounds
onError:        #ffffff  - Text on error
success:        #4CAF50  - Success states
warning:        #FF9800  - Warning states
info:           #2196F3  - Info states
```

### 1.3 Issue State Colors

| State | Color | Hex |
|-------|-------|-----|
| Reported | Orange | `#FF9800` |
| Confirmed | Blue | `#2196F3` |
| In Progress | Purple | `#9C27B0` |
| Fixed | Green | `#4CAF50` |
| Rejected | Gray | `#9E9E9E` |
| Reopened | Red | `#F44336` |

### 1.4 Heat Priority Colors

| Level | Color | Threshold |
|-------|-------|-----------|
| Low | Green | heat < 40 |
| Medium | Orange | heat 40-59 |
| High | Red | heat 60-79 |
| Critical | Purple | heat >= 80 |

## 2. Interaction Feedback

The app uses terracotta-tinted splash colors for touch feedback:

| Property | Value |
|----------|-------|
| Splash Factory | `InkSparkle.splashFactory` |
| Splash Color | secondary @ 12% opacity |
| Highlight Color | secondary @ 8% opacity |

```dart
// Custom splash applied to InkWell
InkWell(
  onTap: () {},
  splashColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
  highlightColor: theme.colorScheme.secondary.withValues(alpha: 0.08),
  child: ...,
)
```

## 3. Component Specifications

All components follow Material Design 3 specifications exactly.

### 3.1 Buttons

| Property | FilledButton | ElevatedButton | OutlinedButton | TextButton |
|----------|-------------|----------------|----------------|------------|
| Height | 40dp | 40dp | 40dp | 40dp |
| Min Width | 64dp | 64dp | 64dp | 48dp |
| Touch Target | 48dp | 48dp | 48dp | 48dp |
| Horizontal Padding | 24dp | 24dp | 24dp | 12dp |
| Shape | Stadium (pill) | Stadium | Stadium | None |
| Elevation | 0 | 1dp | 0 | 0 |
| Text Style | labelLarge | labelLarge | labelLarge | labelLarge |

```dart
// Usage example
FilledButton(
  onPressed: () {},
  child: Text('Primary Action'),
)

OutlinedButton(
  onPressed: () {},
  child: Text('Secondary Action'),
)
```

### 3.2 Cards

| Property | Value | Reason |
|----------|-------|--------|
| Corner Radius | 16dp (Radii.md) | Consistent rounded corners |
| Elevation | 0 | No shadow or surface tint overlay |
| Background | surface (#FAF9F7) | Matches AppBar header strip |
| Border | outlineVariant | Distinct visible border |
| Clip Behavior | antiAlias | Clean edge rendering |

**Important:** Cards use `elevation: 0` and explicit `color: colors.surface` to exactly match the AppBar background. The default M3 card applies a `surfaceTint` overlay at elevation 1, making it visually different from the header.

```dart
// Standard card styling (REQUIRED)
Card(
  elevation: 0,
  color: colors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    side: BorderSide(color: colors.outlineVariant),
  ),
  child: Padding(
    padding: EdgeInsets.all(Spacing.md),
    child: Text('Card content'),
  ),
)
```

### 3.3 Navigation Bar

| Property | Value |
|----------|-------|
| Height | 80dp |
| Background | surfaceContainer |
| Indicator Shape | Stadium (64x32dp pill) |
| Indicator Color | secondaryContainer |
| Icon Size | 24dp |
| Label Style | labelMedium |
| Elevation | 2dp |

### 3.4 Floating Action Button (FAB)

| Size | Dimensions | Icon Size | Corner Radius |
|------|------------|-----------|---------------|
| Standard | 56x56dp | 24dp | 20dp (AppShapes.large) |
| Small | 40x40dp | 24dp | 12dp |
| Large | 96x96dp | 36dp | 28dp |

| Property | Value |
|----------|-------|
| Background | secondary (Terracotta) |
| Foreground | onSecondary |
| Elevation | 3dp |

> **Note:** FAB uses terracotta (secondary) color for visual distinction and brand accent.

### 3.5 Chips

| Property | Value |
|----------|-------|
| Height | 32dp |
| Corner Radius | 8dp (M3 small shape) |
| Horizontal Padding | 16dp |
| Border | 1dp outline |
| Selected Background | secondaryContainer |
| Label Style | labelLarge |

### 3.6 Text Fields

| Property | Value |
|----------|-------|
| Corner Radius | 4dp (M3 extra small shape) |
| Fill Color | surfaceContainerHighest |
| Border Color | outline |
| Focus Border | primary, 2dp |
| Content Padding | 16dp horizontal, 16dp vertical |
| Label Style | bodyLarge |

### 3.7 Dialogs

| Property | Value |
|----------|-------|
| Corner Radius | 28dp (M3 extra large shape) |
| Background | surfaceContainerHigh |
| Elevation | 6dp |

### 3.8 Bottom Sheets

| Property | Value |
|----------|-------|
| Corner Radius | 28dp top (M3 extra large shape) |
| Background | surfaceContainerLow |
| Elevation | 1dp |
| Drag Handle | 32x4dp, onSurfaceVariant |

## 4. Typography

### 4.1 Font Family

**Primary Font:** Source Sans 3 (Google Fonts)

### 4.2 Type Scale

| Style | Size | Weight | Letter Spacing |
|-------|------|--------|----------------|
| displayLarge | 57sp | 400 | -0.25 |
| displayMedium | 45sp | 400 | 0 |
| displaySmall | 36sp | 400 | 0 |
| headlineLarge | 32sp | **700** | 0 |
| headlineMedium | 28sp | **700** | 0 |
| headlineSmall | 24sp | **700** | 0 |
| titleLarge | 24sp | 500 | 0 |
| titleMedium | 18sp | 500 | 0.15 |
| titleSmall | 16sp | 500 | 0.1 |
| bodyLarge | 18sp | 400 | 0.5 |
| bodyMedium | 16sp | 400 | 0.25 |
| bodySmall | 14sp | 400 | 0.4 |
| labelLarge | 16sp | 500 | 0.1 |
| labelMedium | 14sp | 500 | 0.5 |
| labelSmall | 13sp | 500 | 0.5 |

> **Note:** Headlines use weight 700 (bold) for stronger visual hierarchy.

## 5. Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4dp | Tight spacing, icon gaps |
| sm | 8dp | Component internal spacing |
| md | 16dp | Standard spacing, padding |
| lg | 24dp | Section spacing |
| xl | 32dp | Large gaps |
| xxl | 48dp | Major sections |

## 6. Corner Radius Scale (AppShapes)

| Token | Value | Usage |
|-------|-------|-------|
| None | 0dp | Sharp corners |
| Extra Small | 4dp | Inputs, snackbars |
| Small | 8dp | Chips |
| Medium | 16dp | Cards |
| Large | 20dp | FAB |
| Extra Large | 28dp | Dialogs, sheets |
| Full | 9999dp | Pills, stadium shapes |

```dart
// Access via AppShapes class
BorderRadius.circular(AppShapes.medium)  // 16dp
BorderRadius.circular(AppShapes.large)   // 20dp
```

## 7. Dark Theme

Dark theme uses the same color system with inverted brightness. Key differences:

| Element | Light | Dark |
|---------|-------|------|
| Surface | #faf9f7 | #121413 |
| On Surface | #1a1c1b | #e3e2e1 |
| Primary | #0c2721 | #b0cdc3 |
| Primary Container | #233d36 | #233d36 |

## 8. Pod Configuration

Brand colors can be customized per pod deployment:

```dart
PodConfig(
  primaryColor: '#233D36',   // Custom primary
  secondaryColor: '#D9613F', // Custom secondary
  tertiaryColor: '#F3EDDA',  // Custom tertiary
)
```

The theme system regenerates tonal palettes from these seed colors.

## 9. Using Theme Colors

### DO: Use ColorScheme from Theme

```dart
final colors = Theme.of(context).colorScheme;

// Primary actions
Container(color: colors.primary)

// Surface elevation
Container(color: colors.surface) // Cards (matches AppBar)
Container(color: colors.surfaceContainerHigh) // Dialogs

// Text colors
Text('Label', style: TextStyle(color: colors.onSurface))
Text('Secondary', style: TextStyle(color: colors.onSurfaceVariant))
```

### DON'T: Hardcode Colors

```dart
// BAD - hardcoded color
Container(color: Color(0xFF233D36))

// BAD - opacity on theme colors (use semantic variants)
Container(color: colors.primary.withOpacity(0.5))

// GOOD - use the correct semantic color
Container(color: colors.onSurfaceVariant) // for muted content
```

## 10. Issue Type Icons

Each issue type has a distinctive visual representation using the `IssueTypeVisuals` system.

### 10.1 Issue Type Colors

| Type | Icon | Color | Light Color |
|------|------|-------|-------------|
| Pothole | `warning_rounded` | Deep Orange #E65100 | #FFF3E0 |
| Water Leak | `water_drop` | Light Blue #0288D1 | #E1F5FE |
| Sewage Leak | `waves` | Brown #5D4037 | #EFEBE9 |
| Traffic Light | `traffic` | Red #C62828 | #FFEBEE |
| Street Light | `lightbulb` | Amber #F9A825 | #FFFDE7 |
| Illegal Dumping | `delete` | Green #2E7D32 | #E8F5E9 |
| Road Damage | `trending_down` | Blue Grey #37474F | #ECEFF1 |
| Other | `help` | Grey #616161 | #F5F5F5 |

### 10.2 IssueTypeVisuals Class

Centralized configuration for issue type visual representation:

```dart
final visuals = IssueTypeVisuals.forType(IssueType.pothole);

visuals.icon          // Outline icon (warning_amber_rounded)
visuals.filledIcon    // Filled icon (warning_rounded)
visuals.color         // Main color (#E65100)
visuals.lightColor    // Background color (#FFF3E0)
visuals.semanticLabel // Accessibility label ("Pothole hazard")
```

### 10.3 IssueTypeIcon Widget

Large distinctive icon for issue cards and lists:

```dart
// Square icon with rounded corners and background
IssueTypeIcon(
  type: IssueType.pothole,
  size: 64,              // Default: 56
  showBackground: true,  // Default: true
  filled: true,          // Default: true
)

// Icon only without background
IssueTypeIcon(
  type: IssueType.pothole,
  showBackground: false,
)
```

### 10.4 IssueTypeIconCircle Widget

Circular variant for map markers and compact displays:

```dart
IssueTypeIconCircle(
  type: IssueType.waterLeak,
  size: 40,           // Default: 40
  showBorder: true,   // Default: true
)
```

### 10.5 IssueTypeBadge Widget

Compact badge with icon and optional label:

```dart
// With label
IssueTypeBadge(type: IssueType.pothole)

// Icon only
IssueTypeBadge(type: IssueType.pothole, showLabel: false)
```

## 11. Files Reference

| File | Purpose |
|------|---------|
| `mobile/lib/shared/theme/colors.dart` | Color definitions, M3ColorSchemes |
| `mobile/lib/shared/theme/app_theme.dart` | ThemeData builder, AppShapes |
| `mobile/lib/shared/theme/typography.dart` | TextTheme, Spacing, Radii |
| `mobile/lib/shared/theme/issue_type_icons.dart` | IssueTypeVisuals configuration |
| `mobile/lib/shared/providers/theme_provider.dart` | Theme state management |
| `mobile/lib/features/issues/presentation/widgets/issue_type_icon.dart` | IssueTypeIcon, IssueTypeIconCircle |
| `mobile/lib/shared/widgets/empty_state.dart` | EmptyState widget |

## 12. Testing Theme

Run the app and navigate to the theme showcase page to verify all components render correctly with the M3 theme.

```bash
cd mobile
flutter run
# Navigate to Settings > Theme Showcase (dev only)
```
