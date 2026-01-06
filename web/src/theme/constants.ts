/**
 * Berry-inspired layout constants
 * Adapted for MunServ theming
 */

/**
 * Grid spacing constant (Berry uses 3 = 24px)
 * Use with MUI Grid: <Grid container spacing={gridSpacing}>
 */
export const gridSpacing = 3;

/**
 * Drawer/Sidebar widths (Berry pattern)
 */
export const drawerWidth = 260;
export const drawerWidthMini = 72;

/**
 * Header height - DEPRECATED
 * Use theme.mixins.toolbar for responsive header height
 * Kept for backwards compatibility, prefer dynamic calculation
 */
export const headerHeight = 88;

/**
 * Avatar sizes for icon containers
 * Matches Berry's predefined icon avatar sizes
 */
export const avatarSizes = {
  small: {
    width: 22,
    height: 22,
    fontSize: '1rem',
  },
  medium: {
    width: 34,
    height: 34,
    fontSize: '1.25rem',
  },
  large: {
    width: 44,
    height: 44,
    fontSize: '1.5rem',
  },
} as const;

export type AvatarSize = keyof typeof avatarSizes;

/**
 * Common avatar styling (Berry pattern for icon buttons)
 */
export const commonAvatar = {
  cursor: 'pointer',
  borderRadius: '8px',
};

export const mediumAvatar = {
  width: '34px',
  height: '34px',
  fontSize: '1.2rem',
};
