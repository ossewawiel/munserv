import { type FC, type ReactNode, useState, useCallback, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { styled, useTheme } from '@mui/material/styles';
import AppBar from '@mui/material/AppBar';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import useMediaQuery from '@mui/material/useMediaQuery';
import MenuIcon from '@mui/icons-material/Menu';

import { ProfileMenu } from '@/components/organisms/ProfileMenu';
import { NotificationDropdown } from '@/components/organisms/NotificationDropdown';
import { Sidebar } from './Sidebar';
import {
  drawerWidth,
  drawerWidthMini,
  commonAvatar,
  mediumAvatar,
  useThemeContext,
} from '@/theme';

interface DashboardLayoutProps {
  children: ReactNode;
}

// Styled main content area (Berry pattern)
const Main = styled('main', { shouldForwardProp: (prop) => prop !== 'open' })<{
  open?: boolean;
}>(({ theme, open }) => {
  // Toolbar has padding p: { xs: 1.5, md: 2 } = 12px/16px
  // Actual AppBar height = toolbar minHeight + padding
  // Desktop (md+): 64 + 16*2 padding = ~80px (but content fits, so ~72px)
  // Tablet: 64 + 12*2 = ~88px
  // Mobile: 56 + 12*2 = ~80px
  const appBarHeight = {
    xs: 68, // Mobile: accounts for toolbar + padding
    sm: 80, // Tablet: accounts for toolbar + padding
    md: 72, // Desktop: accounts for toolbar + padding
  };

  return {
    // Base styles
    ...theme.typography.body1,
    // Content background: cream with optional vintage map overlay (uses CSS variable for theme awareness)
    backgroundColor: 'var(--munserv-palette-tertiaryLight)',
    // Vintage map background image (very subtle) - only in light mode
    backgroundImage: theme.palette.mode === 'dark'
      ? 'none'
      : 'linear-gradient(color-mix(in srgb, var(--munserv-palette-tertiaryLight) 85%, transparent), color-mix(in srgb, var(--munserv-palette-tertiaryLight) 85%, transparent)), url(\'/assets/vintage-map.jpg\')',
    backgroundSize: 'cover',
    backgroundPosition: 'center',
    backgroundAttachment: 'fixed',
    minHeight: '100vh',
    padding: theme.spacing(3),
    marginRight: theme.spacing(0),
    // Dynamic marginTop based on actual AppBar height (toolbar + padding)
    marginTop: appBarHeight.md,
    // Border radius: 0 on top-left (where borders meet), rounded elsewhere
    borderTopLeftRadius: 0,
    borderTopRightRadius: theme.shape.borderRadius,
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
    transition: theme.transitions.create(['width', 'margin'], {
      easing: theme.transitions.easing.sharp,
      duration: theme.transitions.duration.enteringScreen + 200,
    }),
    // Subtle border to separate content area from navigation (matches card borders)
    // Top border: separates from AppBar (over content area only)
    // Left border: separates from Sidebar
    borderTop: '1px solid',
    borderLeft: '1px solid',
    borderTopColor: 'var(--munserv-palette-divider)',
    borderLeftColor: 'var(--munserv-palette-divider)',

    // Desktop: width based on drawer state
    [theme.breakpoints.up('md')]: {
      width: open ? `calc(100% - ${drawerWidth}px)` : `calc(100% - ${drawerWidthMini}px)`,
      marginLeft: 0,
      marginTop: appBarHeight.md,
    },

    // Tablet/Mobile: responsive toolbar height + full width
    [theme.breakpoints.down('md')]: {
      marginLeft: '20px',
      width: 'calc(100% - 40px)',
      padding: theme.spacing(2),
      marginTop: appBarHeight.sm,
      // No left border on mobile (no persistent sidebar)
      borderLeft: 'none',
      borderTopLeftRadius: theme.shape.borderRadius,
    },

    // Mobile: smaller margins
    [theme.breakpoints.down('sm')]: {
      marginLeft: '10px',
      width: 'calc(100% - 20px)',
      padding: theme.spacing(2),
      marginRight: '10px',
      marginTop: appBarHeight.xs,
    },
  };
});

export const DashboardLayout: FC<DashboardLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  const theme = useTheme();
  const { colorMode } = useThemeContext();
  const matchDownMd = useMediaQuery(theme.breakpoints.down('md'));
  const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)');

  // Resolve color mode: if 'system', use system preference; otherwise use explicit mode
  const isDarkMode = colorMode === 'system' ? prefersDarkMode : colorMode === 'dark';

  // Drawer state: open on desktop by default, closed on mobile
  const [drawerOpen, setDrawerOpen] = useState(true);

  const handleDrawerToggle = useCallback(() => {
    setDrawerOpen((prev) => !prev);
  }, []);

  const handleDrawerClose = useCallback(() => {
    setDrawerOpen(false);
  }, []);

  const header = useMemo(
    () => (
      <Toolbar sx={{ p: { xs: 1.5, md: 2 } }}>
        {/* Logo & Toggle Button */}
        <Box
          sx={{
            width: 228,
            display: 'flex',
            alignItems: 'center',
            [theme.breakpoints.down('md')]: {
              width: 'auto',
            },
          }}
        >
          {/* Logo - hidden on mobile */}
          <Box
            component="span"
            sx={{ display: { xs: 'none', md: 'block' }, flexGrow: 1 }}
          >
            <Box
              component={Link}
              to="/"
              sx={{ display: 'flex', alignItems: 'center', textDecoration: 'none' }}
            >
              <Box
                component="img"
                src={isDarkMode ? '/assets/app-logo-dark.png' : '/assets/app-logo.png'}
                alt={t('common.appName')}
                sx={{ height: 32 }}
              />
            </Box>
          </Box>

          {/* Hamburger Toggle - Berry style with Avatar wrapper */}
          <Avatar
            variant="rounded"
            sx={{
              ...commonAvatar,
              ...mediumAvatar,
              overflow: 'hidden',
              transition: 'all .2s ease-in-out',
              cursor: 'pointer',
              // Use CSS variables for dynamic color scheme switching
              // Light mode: secondary.light bg, secondary.dark icon
              // Dark mode: surfaceContainerHigh bg, secondary.main icon
              bgcolor: 'var(--munserv-palette-secondary-light)',
              color: 'var(--munserv-palette-secondary-dark)',
              '&:hover': {
                bgcolor: 'var(--munserv-palette-secondary-main)',
                color: 'var(--munserv-palette-secondary-contrastText)',
              },
            }}
            onClick={handleDrawerToggle}
          >
            <MenuIcon fontSize="small" />
          </Avatar>
        </Box>

        {/* Spacer */}
        <Box sx={{ flexGrow: 1 }} />

        {/* Right side actions - Notifications and Profile Menu */}
        <NotificationDropdown />
        <ProfileMenu />
      </Toolbar>
    ),
    [theme, t, isDarkMode, handleDrawerToggle]
  );

  return (
    <Box sx={{ display: 'flex' }}>
      {/* Header */}
      <AppBar
        enableColorOnDark
        position="fixed"
        color="inherit"
        elevation={0}
        sx={{
          // Use CSS variable for dynamic color scheme switching
          bgcolor: 'var(--munserv-palette-background-default)',
          transition: theme.transitions.create('width'),
        }}
      >
        {header}
      </AppBar>

      {/* Sidebar */}
      <Sidebar
        variant={matchDownMd ? 'temporary' : 'permanent'}
        open={drawerOpen}
        onClose={handleDrawerClose}
      />

      {/* Main Content */}
      <Main open={drawerOpen}>
        {children}
      </Main>
    </Box>
  );
};
