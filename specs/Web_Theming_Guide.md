# Web Theming Guide

MUI v7 theming specification for the MunServ web admin portal.

## 1. Color System

### 1.1 Brand Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary | Forest Green | `#233D36` | Primary actions, key UI elements |
| Secondary | Terracotta | `#D9613F` | Secondary actions, accents, CTAs |
| Tertiary | Warm Beige | `#F1EDDA` | Backgrounds, tertiary elements |

### 1.2 MUI Color Roles

The app uses MUI's palette system with colors generated from the brand colors via Material Theme Builder. All color roles are defined in the theme configuration.

#### Primary Palette (Forest Green)
```
primary.main:          #0C2721  - Primary actions, prominent buttons
primary.contrastText:  #FFFFFF  - Text/icons on primary
primaryContainer:      #233D36  - Less prominent containers
onPrimaryContainer:    #8BA89E  - Text on primary container
```

#### Secondary Palette (Terracotta)
```
secondary.main:          #A2391A  - Secondary actions
secondary.contrastText:  #FFFFFF  - Text/icons on secondary
secondaryContainer:      #C35130  - Nav indicators, selected states
onSecondaryContainer:    #FFFBFF  - Text on secondary container
```

#### Tertiary Palette (Beige)
```
tertiary:             #615F50  - Tertiary accents
onTertiary:           #FFFFFF  - Text/icons on tertiary
tertiaryContainer:    #F1EDDA  - Tertiary backgrounds
onTertiaryContainer:  #6D6B5C  - Text on tertiary container
```

#### Surface Colors (MUI Elevation System)
```
background.default:       #FAF9F7  - Page background
background.paper:         #FAF9F7  - Card/paper background
surfaceContainerLowest:   #FFFFFF  - Lowest elevation
surfaceContainerLow:      #F4F3F2  - Cards, dialogs
surfaceContainer:         #EFEEEC  - Navigation bars
surfaceContainerHigh:     #E9E8E6  - Dialogs, menus
surfaceContainerHighest:  #E3E2E1  - Inputs, active states
```

#### Semantic Colors
```
error.main:       #BA1A1A  - Error states
error.light:      #FFDAD6  - Error backgrounds
success.main:     #4CAF50  - Success states
warning.main:     #FF9800  - Warning states
info.main:        #2196F3  - Info states
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

## 2. Component Specifications

All components use MUI v7 with custom theme overrides.

### 2.1 Buttons

| Property | Contained | Outlined | Text |
|----------|-----------|----------|------|
| Height | 40px | 40px | 40px |
| Min Width | 64px | 64px | 48px |
| Horizontal Padding | 24px | 24px | 12px |
| Border Radius | 8px (medium) | 8px | 8px |
| Elevation | 0 | 0 | 0 |
| Text Transform | none | none | none |

```typescript
// Usage example
<Button variant="contained" color="primary">
  Primary Action
</Button>

<Button variant="outlined" color="inherit">
  Secondary Action
</Button>

<Button variant="text" color="error">
  Danger Action
</Button>
```

### 2.2 Cards

| Property | Value |
|----------|-------|
| Border Radius | 12px (MUI medium shape) |
| Elevation | 1 |
| Background | background.paper |
| Border | 1px solid divider |

```typescript
// Usage example
<Card variant="outlined">
  <CardContent>
    <Typography variant="h6">Card Title</Typography>
    <Typography variant="body2" color="text.secondary">
      Card content
    </Typography>
  </CardContent>
</Card>
```

### 2.3 App Bar (Navigation)

| Property | Value |
|----------|-------|
| Height | 64px |
| Background | background.paper |
| Elevation | 1 |
| Position | sticky |

### 2.4 Chips

| Property | Value |
|----------|-------|
| Height | 32px |
| Border Radius | 8px |
| Horizontal Padding | 12px |
| Selected Background | secondary.main |
| Label Style | body2 |

### 2.5 Text Fields

| Property | Value |
|----------|-------|
| Variant | outlined |
| Size | small |
| Border Radius | 4px |
| Border Color | divider |
| Focus Border | primary.main, 2px |

### 2.6 Dialogs

| Property | Value |
|----------|-------|
| Border Radius | 28px (MUI extra large shape) |
| Background | background.paper |
| Elevation | 24 |
| Max Width | sm (600px) |

### 2.7 Tables

| Property | Value |
|----------|-------|
| Header Background | surfaceContainerLow |
| Row Hover | action.hover |
| Border | 1px solid divider |
| Cell Padding | 16px |

## 3. Typography

### 3.1 Font Family

**Primary Font:** Source Sans 3 (Google Fonts)

```typescript
fontFamily: '"Source Sans 3", "Roboto", "Helvetica", "Arial", sans-serif'
```

### 3.2 MUI Type Scale

| Style | Size | Weight | Letter Spacing |
|-------|------|--------|----------------|
| h1 | 96px | 300 | -1.5px |
| h2 | 60px | 300 | -0.5px |
| h3 | 48px | 400 | 0 |
| h4 | 34px | 400 | 0.25px |
| h5 | 24px | 500 | 0 |
| h6 | 20px | 500 | 0.15px |
| subtitle1 | 16px | 400 | 0.15px |
| subtitle2 | 14px | 500 | 0.1px |
| body1 | 16px | 400 | 0.5px |
| body2 | 14px | 400 | 0.25px |
| button | 14px | 500 | 0.4px |
| caption | 12px | 400 | 0.4px |
| overline | 10px | 400 | 1.5px |

## 4. Spacing Scale

MUI uses an 8px spacing system by default.

| Token | Value | Usage |
|-------|-------|-------|
| 0.5 | 4px | Tight spacing, icon gaps |
| 1 | 8px | Component internal spacing |
| 2 | 16px | Standard spacing, padding |
| 3 | 24px | Section spacing |
| 4 | 32px | Large gaps |
| 6 | 48px | Major sections |

```typescript
// Usage example
<Box sx={{ p: 2, mb: 3, gap: 1 }}>
  {/* p: 16px, mb: 24px, gap: 8px */}
</Box>
```

## 5. Border Radius Scale (MUI Shape)

| Token | Value | Usage |
|-------|-------|-------|
| shape.borderRadius | 8px | Default radius |
| 0 | 0px | Sharp corners |
| 1 | 4px | Inputs, snackbars |
| 2 | 8px | Chips, buttons |
| 3 | 12px | Cards |
| 4 | 16px | FAB |
| 7 | 28px | Dialogs, sheets |

```typescript
// Usage example
<Box sx={{ borderRadius: 2 }}>  {/* 8px */}
<Paper sx={{ borderRadius: 3 }}> {/* 12px */}
```

## 6. Dark Theme

Dark theme uses the same color system with inverted brightness.

| Element | Light | Dark |
|---------|-------|------|
| background.default | #FAF9F7 | #121413 |
| background.paper | #FAF9F7 | #1E201F |
| text.primary | #1A1C1B | #E3E2E1 |
| text.secondary | #424846 | #C1C8C4 |
| primary.main | #0C2721 | #B0CDC3 |
| primary.contrastText | #FFFFFF | #1B352E |
| divider | #E2E3E1 | #424846 |

### Color Mode Toggle

```typescript
import { useColorScheme } from '@mui/material/styles';
import IconButton from '@mui/material/IconButton';
import LightModeIcon from '@mui/icons-material/LightMode';
import DarkModeIcon from '@mui/icons-material/DarkMode';

function ColorModeToggle() {
  const { mode, setMode } = useColorScheme();

  return (
    <IconButton onClick={() => setMode(mode === 'light' ? 'dark' : 'light')}>
      {mode === 'light' ? <DarkModeIcon /> : <LightModeIcon />}
    </IconButton>
  );
}
```

## 7. Pod Configuration

Brand colors can be customized per pod deployment.

### 7.1 Configuration Interface

```typescript
interface PodThemeConfig {
  podId: string;
  fonts: {
    primary: string;        // e.g., "Source Sans 3"
    fallback?: string;      // e.g., "sans-serif"
  };
  colors: {
    primary: string;        // e.g., "#233D36"
    secondary: string;      // e.g., "#D9613F"
    tertiary?: string;      // e.g., "#F1EDDA"
  };
  logo?: string;            // URL to pod logo
}
```

### 7.2 Runtime Theme Loading

```typescript
// Theme loads pod config on mount
useEffect(() => {
  const loadPodTheme = async () => {
    const podId = window.location.hostname.split('.')[0];
    const response = await fetch(`/api/v1/pods/${podId}/theme`);
    if (response.ok) {
      const config = await response.json();
      setTheme(createPodTheme(config));
    }
  };
  loadPodTheme();
}, []);
```

### 7.3 Environment Variable Override

```env
VITE_POD_PRIMARY_COLOR=#233D36
VITE_POD_SECONDARY_COLOR=#D9613F
VITE_POD_FONT_FAMILY="Source Sans 3"
```

## 8. Using Theme Colors

### DO: Use MUI's sx Prop with Theme Tokens

```typescript
// Semantic color usage
<Box sx={{ bgcolor: 'primary.main', color: 'primary.contrastText' }}>
  Primary container
</Box>

// Background levels
<Paper sx={{ bgcolor: 'background.paper' }}>
<Card sx={{ bgcolor: 'background.default' }}>

// Text colors
<Typography color="text.primary">Main text</Typography>
<Typography color="text.secondary">Muted text</Typography>

// Responsive spacing
<Box sx={{ p: { xs: 2, sm: 3, md: 4 } }}>
```

### DO: Use CSS Variables for Dynamic Access

```typescript
// Access via CSS variables (when cssVariables: true)
<Box sx={{ bgcolor: 'var(--munserv-palette-primary-main)' }}>

// In plain CSS
.custom-element {
  background-color: var(--munserv-palette-primary-main);
  color: var(--munserv-palette-primary-contrastText);
}
```

### DON'T: Hardcode Colors

```typescript
// BAD - hardcoded color
<Box sx={{ bgcolor: '#233D36' }}>

// BAD - using alpha on theme colors
<Box sx={{ bgcolor: alpha(theme.palette.primary.main, 0.5) }}>

// GOOD - use semantic color tokens
<Box sx={{ bgcolor: 'primary.light' }}>  // for lighter variant
<Box sx={{ bgcolor: 'action.hover' }}>   // for hover states
```

## 9. Files Reference

| File | Purpose |
|------|---------|
| `web/src/theme/index.ts` | Theme exports |
| `web/src/theme/types.ts` | TypeScript interfaces |
| `web/src/theme/colors.ts` | Color constants from material-theme.json |
| `web/src/theme/createPodTheme.ts` | Theme factory with CSS variables |
| `web/src/theme/defaultTheme.ts` | Default pod configuration |
| `web/src/theme/ThemeContext.tsx` | Theme provider with runtime loading |
| `web/material-theme.json` | Material Theme Builder export (source of truth) |

## 10. Testing Theme

Run the app and verify all components render correctly with the theme.

```bash
cd web
pnpm dev
# Open http://localhost:3000
# Test light/dark mode toggle
# Verify colors match material-theme.json
```

### Visual Checklist

- [ ] Primary buttons use Forest Green (#0C2721)
- [ ] Secondary actions use Terracotta (#A2391A)
- [ ] Cards have proper elevation and borders
- [ ] Text is readable in both light and dark modes
- [ ] Issue state badges show correct colors
- [ ] Heat indicators display proper priority colors
- [ ] Navigation bar is properly styled
- [ ] Forms have correct focus states

## 11. Component Theme Overrides

The theme includes default component overrides for consistency:

```typescript
components: {
  MuiButton: {
    defaultProps: {
      disableElevation: true,
    },
    styleOverrides: {
      root: {
        textTransform: 'none',
        fontWeight: 500,
        borderRadius: 8,
      },
    },
  },
  MuiTextField: {
    defaultProps: {
      variant: 'outlined',
      size: 'small',
    },
  },
  MuiCard: {
    defaultProps: {
      variant: 'outlined',
    },
    styleOverrides: {
      root: {
        borderRadius: 12,
      },
    },
  },
  MuiChip: {
    styleOverrides: {
      root: {
        fontWeight: 500,
        borderRadius: 8,
      },
    },
  },
  MuiDialog: {
    styleOverrides: {
      paper: {
        borderRadius: 28,
      },
    },
  },
}
```
