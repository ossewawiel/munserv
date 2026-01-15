# Feature: Mobile Theme Refinement

## Summary

Finalize the Material Design 3 look and feel for the MunServ mobile app with distinctive issue type icons and enhanced visual identity.

## Goals

1. **Distinctive Issue Type Icons** - Replace photo thumbnails in issue lists with branded, colorful icons that instantly communicate issue type
2. **Enhanced M3 Compliance** - Ensure all components follow Material 3 guidelines with app-specific refinements
3. **Visual Consistency** - Unify colors, shapes, and interactions across all screens
4. **Brand Expression** - Make the app feel unique within M3 constraints using the Forest Green + Terracotta palette

## User Stories

- As a member, I can quickly identify issue types in lists by their distinctive icons
- As a member, I experience consistent, polished interactions throughout the app
- As a member, the app feels professional and unique compared to generic apps

## Scope

### In Scope
- Custom issue type icon system (8 types)
- Updated issue card layout (icon instead of thumbnail)
- Enhanced shape system (larger radii)
- Terracotta-tinted interaction feedback
- Bolder headline typography
- Reusable empty state components
- FAB accent color change to terracotta

### Out of Scope
- Custom illustrations or artwork
- Animation enhancements
- Dark mode changes (uses existing system)
- New screens or navigation changes

## Technical Approach

See `implementation-plan.md` for detailed implementation steps.

### New Files
- `lib/shared/theme/issue_type_icons.dart` - Centralized icon/color config
- `lib/features/issues/presentation/widgets/issue_type_icon.dart` - Icon widgets
- `lib/shared/widgets/empty_state.dart` - Reusable empty states

### Modified Files
- Issue card, type badge, theme, typography, report page

## Design Decisions

### Icon Style
- **Rounded square background** for list cards (64x64dp)
- **Circular variant** available for map markers
- Each type has unique color + light background for accessibility

### Color Palette (Issue Types)
| Type | Color | Rationale |
|------|-------|-----------|
| Pothole | Deep Orange | Warning/hazard association |
| Water Leak | Light Blue | Water association |
| Sewage Leak | Brown | Earthy/dirty association |
| Traffic Light | Red | Stop/alert association |
| Street Light | Amber | Light/glow association |
| Illegal Dumping | Green | Environmental concern |
| Road Damage | Blue Grey | Asphalt/infrastructure |
| Other | Grey | Neutral/generic |

### Shape Decisions
- Cards: 16dp radius (up from 12dp) - more approachable
- FAB: 20dp radius - matches card language
- Keep M3 standard for buttons/inputs

### Interaction Feedback
- Ripple color: `secondary.withValues(alpha: 0.12)` (terracotta tint)
- Creates warmer feel matching brand palette

## Dependencies

- No new packages required
- Uses existing Material icons (no custom SVGs needed)

## Testing

- Widget tests for new `IssueTypeIcon` component
- Visual regression in theme showcase page
- Manual verification of all issue types

## Related

- `mobile/CLAUDE.md` - Mobile development guidelines
- `specs/Mobile_Theming_Guide.md` - Full theming specification
- `mobile/lib/shared/theme/colors.dart` - Color system
