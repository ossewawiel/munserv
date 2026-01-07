import { styled, type Theme } from '@mui/material/styles';
import Drawer from '@mui/material/Drawer';
import { drawerWidth, drawerWidthMini } from '@/theme';

const openedMixin = (theme: Theme) => ({
  width: drawerWidth,
  borderRight: 'none',
  zIndex: 1099,
  // Use CSS variable for dynamic color scheme switching
  background: 'var(--munserv-palette-background-default)',
  overflowX: 'hidden' as const,
  boxShadow: theme.shadows[1],
  transition: theme.transitions.create('width', {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.enteringScreen + 200,
  }),
});

const closedMixin = (theme: Theme) => ({
  borderRight: 'none',
  zIndex: 1099,
  // Use CSS variable for dynamic color scheme switching
  background: 'var(--munserv-palette-background-default)',
  overflowX: 'hidden' as const,
  width: drawerWidthMini,
  transition: theme.transitions.create('width', {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.leavingScreen + 200,
  }),
});

interface MiniDrawerStyledProps {
  open?: boolean;
}

export const MiniDrawerStyled = styled(Drawer, {
  shouldForwardProp: (prop) => prop !== 'open',
})<MiniDrawerStyledProps>(({ theme, open }) => ({
  borderRight: '0px',
  flexShrink: 0,
  whiteSpace: 'nowrap',
  boxSizing: 'border-box',
  // Width changes based on open/closed state
  width: open ? drawerWidth : drawerWidthMini,
  transition: theme.transitions.create('width', {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.enteringScreen + 200,
  }),
  ...(open && {
    '& .MuiDrawer-paper': openedMixin(theme),
  }),
  ...(!open && {
    '& .MuiDrawer-paper': closedMixin(theme),
  }),
}));
