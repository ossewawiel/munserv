import { type FC, type ReactNode, useState, useCallback } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import MuiButton from '@mui/material/Button';
import Container from '@mui/material/Container';
import Drawer from '@mui/material/Drawer';
import IconButton from '@mui/material/IconButton';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import MenuIcon from '@mui/icons-material/Menu';
import CloseIcon from '@mui/icons-material/Close';

import { useLogout } from '@/features/auth/hooks';
import { Button } from '@/components/atoms/Button';

interface NavItem {
  labelKey: string;
  href: string;
}

const navItems: NavItem[] = [
  { labelKey: 'nav.dashboard', href: '/' },
  { labelKey: 'nav.issues', href: '/issues' },
  { labelKey: 'nav.heatReport', href: '/reports/heat' },
  { labelKey: 'nav.members', href: '/members' },
];

interface DashboardLayoutProps {
  children: ReactNode;
}

export const DashboardLayout: FC<DashboardLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  const location = useLocation();
  const navigate = useNavigate();
  const logout = useLogout();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = useCallback(() => {
    logout.mutate(undefined, {
      onSuccess: () => {
        navigate('/login');
      },
      onError: () => {
        // Even if API call fails, clear local state and redirect
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('admin');
        navigate('/login');
      },
    });
  }, [logout, navigate]);

  const toggleMobileMenu = useCallback(() => {
    setMobileMenuOpen((prev) => !prev);
  }, []);

  const closeMobileMenu = useCallback(() => {
    setMobileMenuOpen(false);
  }, []);

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* Header */}
      <AppBar position="static" color="default" elevation={1}>
        <Container maxWidth="xl">
          <Toolbar disableGutters sx={{ justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Typography variant="h6" component="h1" fontWeight={700}>
                {t('common.appName')}
              </Typography>
              {/* Desktop navigation */}
              <Box
                component="nav"
                sx={{
                  display: { xs: 'none', sm: 'flex' },
                  ml: 4,
                  gap: 0.5,
                }}
              >
                {navItems.map((item) => (
                  <MuiButton
                    key={item.href}
                    component={Link}
                    to={item.href}
                    variant={location.pathname === item.href ? 'contained' : 'text'}
                    color={location.pathname === item.href ? 'primary' : 'inherit'}
                    size="small"
                  >
                    {t(item.labelKey)}
                  </MuiButton>
                ))}
              </Box>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              {/* Mobile menu button */}
              <IconButton
                onClick={toggleMobileMenu}
                sx={{ display: { sm: 'none' } }}
                aria-label={mobileMenuOpen ? 'Close menu' : 'Open menu'}
              >
                {mobileMenuOpen ? <CloseIcon /> : <MenuIcon />}
              </IconButton>
              {/* Logout button */}
              <Button
                variant="secondary"
                size="small"
                onClick={handleLogout}
                isLoading={logout.isPending}
                sx={{ display: { xs: 'none', sm: 'inline-flex' } }}
              >
                {t('auth.logout')}
              </Button>
            </Box>
          </Toolbar>
        </Container>
      </AppBar>

      {/* Mobile menu */}
      <Drawer
        anchor="top"
        open={mobileMenuOpen}
        onClose={closeMobileMenu}
        sx={{
          display: { sm: 'none' },
          '& .MuiDrawer-paper': {
            top: 64,
            bgcolor: 'background.paper',
          },
        }}
      >
        <List>
          {navItems.map((item) => (
            <ListItemButton
              key={item.href}
              component={Link}
              to={item.href}
              selected={location.pathname === item.href}
              onClick={closeMobileMenu}
            >
              <ListItemText primary={t(item.labelKey)} />
            </ListItemButton>
          ))}
          <ListItemButton
            onClick={() => {
              closeMobileMenu();
              handleLogout();
            }}
            sx={{ color: 'error.main' }}
          >
            <ListItemText primary={t('auth.logout')} />
          </ListItemButton>
        </List>
      </Drawer>

      {/* Main content */}
      <Container component="main" maxWidth="xl" sx={{ py: 3 }}>
        {children}
      </Container>
    </Box>
  );
};
