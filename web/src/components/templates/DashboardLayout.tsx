import { type FC, type ReactNode, useState, useCallback, useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { styled, useTheme } from '@mui/material/styles';
import AppBar from '@mui/material/AppBar';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import useMediaQuery from '@mui/material/useMediaQuery';
import MenuIcon from '@mui/icons-material/Menu';

import { useLogout } from '@/features/auth/hooks';
import { Button } from '@/components/atoms/Button';
import { Sidebar } from './Sidebar';
import {
  drawerWidth,
  drawerWidthMini,
  commonAvatar,
  mediumAvatar,
  lightScheme,
  darkScheme,
} from '@/theme';

interface DashboardLayoutProps {
  children: ReactNode;
}

// Styled main content area (Berry pattern)
const Main = styled('main', { shouldForwardProp: (prop) => prop !== 'open' })<{
  open?: boolean;
}>(({ theme, open }) => {
  // Get toolbar height from theme mixins (responsive)
  const toolbarMinHeight = theme.mixins.toolbar.minHeight as number;

  return {
    // Base styles
    ...theme.typography.body1,
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
    // Content background: cream with optional vintage map overlay
    backgroundColor: theme.palette.mode === 'dark'
      ? darkScheme.tertiaryLight
      : lightScheme.tertiaryLight,
    // Vintage map background image (very subtle)
    backgroundImage: theme.palette.mode === 'dark'
      ? 'none'
      : `linear-gradient(${lightScheme.tertiaryLight}D9, ${lightScheme.tertiaryLight}D9), url('/assets/vintage-map.jpg')`,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
    backgroundAttachment: 'fixed',
    minHeight: '100vh',
    padding: theme.spacing(3),
    marginRight: theme.spacing(0),
    // Dynamic marginTop based on toolbar height
    marginTop: toolbarMinHeight,
    borderRadius: `${theme.shape.borderRadius}px`,
    transition: theme.transitions.create(['width', 'margin'], {
      easing: theme.transitions.easing.sharp,
      duration: theme.transitions.duration.enteringScreen + 200,
    }),

    // Desktop: width based on drawer state
    [theme.breakpoints.up('md')]: {
      width: open ? `calc(100% - ${drawerWidth}px)` : `calc(100% - ${drawerWidthMini}px)`,
      marginLeft: 0,
    },

    // Tablet/Mobile: responsive toolbar height + full width
    [theme.breakpoints.down('md')]: {
      marginLeft: '20px',
      width: 'calc(100% - 40px)',
      padding: theme.spacing(2),
      marginTop: 64, // Standard MUI toolbar height for sm+
    },

    // Mobile: smaller margins
    [theme.breakpoints.down('sm')]: {
      marginLeft: '10px',
      width: 'calc(100% - 20px)',
      padding: theme.spacing(2),
      marginRight: '10px',
      marginTop: 56, // MUI mobile toolbar height
    },
  };
});

export const DashboardLayout: FC<DashboardLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const logout = useLogout();
  const theme = useTheme();
  const matchDownMd = useMediaQuery(theme.breakpoints.down('md'));

  // Drawer state: open on desktop by default, closed on mobile
  const [drawerOpen, setDrawerOpen] = useState(true);

  const handleLogout = useCallback(() => {
    logout.mutate(undefined, {
      onSuccess: () => {
        navigate('/login');
      },
      onError: () => {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('admin');
        navigate('/login');
      },
    });
  }, [logout, navigate]);

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
            <Typography
              variant="h6"
              component={Link}
              to="/"
              sx={{
                fontWeight: 700,
                color: 'text.primary',
                textDecoration: 'none',
                '&:hover': { color: 'primary.main' },
              }}
            >
              {t('common.appName')}
            </Typography>
          </Box>

          {/* Hamburger Toggle - Berry style with Avatar wrapper */}
          <Avatar
            variant="rounded"
            sx={{
              ...commonAvatar,
              ...mediumAvatar,
              overflow: 'hidden',
              transition: 'all .2s ease-in-out',
              background: theme.palette.mode === 'dark'
                ? theme.palette.grey[800]
                : theme.palette.secondary.light,
              color: theme.palette.mode === 'dark'
                ? theme.palette.secondary.main
                : theme.palette.secondary.dark,
              '&:hover': {
                background: theme.palette.mode === 'dark'
                  ? theme.palette.secondary.main
                  : theme.palette.secondary.dark,
                color: theme.palette.secondary.light,
              },
            }}
            onClick={handleDrawerToggle}
          >
            <MenuIcon fontSize="small" />
          </Avatar>
        </Box>

        {/* Spacer */}
        <Box sx={{ flexGrow: 1 }} />

        {/* Right side actions */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Button
            variant="secondary"
            size="small"
            onClick={handleLogout}
            isLoading={logout.isPending}
          >
            {t('auth.logout')}
          </Button>
        </Box>
      </Toolbar>
    ),
    [theme, t, handleDrawerToggle, handleLogout, logout.isPending]
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
          bgcolor: theme.palette.background.default,
          transition: theme.transitions.create('width'),
        }}
      >
        {header}
      </AppBar>

      {/* Sidebar */}
      <Sidebar
        variant={matchDownMd ? 'temporary' : 'permanent'}
        open={matchDownMd ? drawerOpen : drawerOpen}
        onClose={handleDrawerClose}
      />

      {/* Main Content */}
      <Main open={drawerOpen}>
        {children}
      </Main>
    </Box>
  );
};
