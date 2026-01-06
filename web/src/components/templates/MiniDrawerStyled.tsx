import { styled } from '@mui/material/styles';
import Drawer from '@mui/material/Drawer';
import { drawerWidth, drawerWidthMini } from '@/theme';

const openedMixin = (theme: typeof import('@mui/material/styles').useTheme extends () => infer T ? T : never) => ({
  width: drawerWidth,
  borderRight: 'none',
  zIndex: 1099,
  background: theme.palette.background.default,
  overflowX: 'hidden' as const,
  boxShadow: theme.palette.mode === 'dark' ? theme.shadows[1] : 'none',
  transition: theme.transitions.create('width', {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.enteringScreen + 200,
  }),
});

const closedMixin = (theme: typeof import('@mui/material/styles').useTheme extends () => infer T ? T : never) => ({
  borderRight: 'none',
  zIndex: 1099,
  background: theme.palette.background.default,
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
