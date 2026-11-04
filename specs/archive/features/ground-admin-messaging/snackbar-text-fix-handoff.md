# Bug Fix: Unreadable snackbar text when submitting ground admin request

**Issue:** [#6](https://github.com/ossewawiel/munserv/issues/6)
**Status:** In Progress
**Platform(s):** Mobile (Flutter)

## Problem

When accepting an invite as ground admin, the snackbar does not display text correctly. The text follows dark color guidelines but appears on a dark primary background color, making it nearly unreadable.

**Steps to Reproduce:**
1. Go to messages
2. Tap invite message to open details
3. Accept invite as ground admin

**Expected:** Snackbar text should be a lighter/white color for readability on dark background.

**Actual:** Text color is dark and barely distinguishable from primary background.

## Root Cause

In `app_theme.dart`, the snackbar theme had incorrect text color:

```dart
snackBarTheme: SnackBarThemeData(
  backgroundColor: colorScheme.inverseSurface,  // Dark background
  contentTextStyle: textTheme.bodyMedium?.copyWith(
    color: colorScheme.onSurface,  // BUG: Dark text on dark background
  ),
```

The `onSurface` color is meant for light backgrounds, but snackbars use `inverseSurface` (dark). The correct pairing is `onInverseSurface`.

## Affected Files

- `mobile/lib/shared/theme/app_theme.dart:242-244` - Snackbar theme configuration

## Fix Approach

Changed `colorScheme.onSurface` to `colorScheme.onInverseSurface` in the snackbar theme's `contentTextStyle`. This follows M3 color pairing rules:

| Background | Text Color |
|------------|------------|
| `surface` | `onSurface` |
| `inverseSurface` | `onInverseSurface` |

## Testing

- [ ] Unit tests (if applicable)
- [ ] Manual verification on light theme
- [ ] Manual verification on dark theme
- [ ] Regression check on other snackbars

## Verification

1. Open mobile app
2. Navigate to Messages
3. Tap an invite message
4. Accept the ground admin invite
5. Verify snackbar text is clearly readable (white/light on dark background)
