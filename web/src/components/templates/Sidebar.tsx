import { type FC, useMemo } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Tooltip from '@mui/material/Tooltip';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme, alpha } from '@mui/material/styles';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AssignmentIcon from '@mui/icons-material/Assignment';
import WhatshotIcon from '@mui/icons-material/Whatshot';
import PeopleIcon from '@mui/icons-material/People';

import { drawerWidth } from '@/theme';
import { MiniDrawerStyled } from './MiniDrawerStyled';

/** Get the color for selected/hovered items based on theme mode */
const getItemColor = (isDarkMode: boolean): string =>
  isDarkMode ? 'secondary.main' : 'secondary.dark';

interface NavItem {
  labelKey: string;
  href: string;
  icon: React.ElementType;
}

const navItems: NavItem[] = [
  { labelKey: 'nav.dashboard', href: '/', icon: DashboardIcon },
  { labelKey: 'nav.issues', href: '/issues', icon: AssignmentIcon },
  { labelKey: 'nav.heatReport', href: '/reports/heat', icon: WhatshotIcon },
  { labelKey: 'nav.members', href: '/members', icon: PeopleIcon },
];

interface SidebarProps {
  open: boolean;
  onClose: () => void;
  variant: 'permanent' | 'temporary';
}

export const Sidebar: FC<SidebarProps> = ({ open, onClose, variant }) => {
  const { t } = useTranslation();
  const location = useLocation();
  const theme = useTheme();
  const matchDownMd = useMediaQuery(theme.breakpoints.down('md'));

  const isSelected = (href: string): boolean => {
    if (href === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(href);
  };

  const logo = useMemo(
    () => (
      <Box sx={{ display: 'flex', p: 2, alignItems: 'center' }}>
        <Typography
          component={Link}
          to="/"
          variant="h6"
          sx={{
            fontWeight: 700,
            color: 'text.primary',
            textDecoration: 'none',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            '&:hover': { color: 'primary.main' },
          }}
        >
          {open ? t('common.appName') : 'M'}
        </Typography>
      </Box>
    ),
    [open, t]
  );

  const drawerContent = (
    <Box sx={{ overflow: 'auto', mt: open ? 0 : 2 }}>
      <List sx={{ px: open ? 2 : 0.5 }}>
        {navItems.map((item) => {
          const Icon = item.icon;
          const selected = isSelected(item.href);

          const listItem = (
            <ListItemButton
              key={item.href}
              component={Link}
              to={item.href}
              selected={selected}
              onClick={variant === 'temporary' ? onClose : undefined}
              sx={{
                minHeight: 44,
                borderRadius: 2,
                mb: 0.5,
                px: open ? 2 : 1.5,
                justifyContent: open ? 'initial' : 'center',
                '&.Mui-selected': {
                  bgcolor: alpha(theme.palette.secondary.main, 0.15),
                  color: getItemColor(theme.palette.mode === 'dark'),
                  '&:hover': {
                    bgcolor: alpha(theme.palette.secondary.main, 0.2),
                  },
                  '& .MuiListItemIcon-root': {
                    color: getItemColor(theme.palette.mode === 'dark'),
                  },
                },
                '&:hover': {
                  bgcolor: alpha(theme.palette.secondary.main, 0.1),
                  color: getItemColor(theme.palette.mode === 'dark'),
                  '& .MuiListItemIcon-root': {
                    color: getItemColor(theme.palette.mode === 'dark'),
                  },
                },
              }}
            >
              <ListItemIcon
                sx={{
                  minWidth: open ? 36 : 'auto',
                  mr: open ? 1.5 : 0,
                  justifyContent: 'center',
                  color: selected
                    ? getItemColor(theme.palette.mode === 'dark')
                    : 'text.primary',
                }}
              >
                <Icon />
              </ListItemIcon>
              {open && (
                <ListItemText
                  primary={t(item.labelKey)}
                  slotProps={{
                    primary: {
                      fontWeight: selected ? 600 : 400,
                      fontSize: '0.875rem',
                    },
                  }}
                />
              )}
            </ListItemButton>
          );

          // Wrap in tooltip when drawer is collapsed
          if (!open && variant === 'permanent') {
            return (
              <Tooltip key={item.href} title={t(item.labelKey)} placement="right" arrow>
                {listItem}
              </Tooltip>
            );
          }

          return listItem;
        })}
      </List>
    </Box>
  );

  // Mobile: temporary drawer
  if (matchDownMd) {
    return (
      <Drawer
        variant="temporary"
        anchor="left"
        open={open}
        onClose={onClose}
        sx={{
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            // Use CSS variable for dynamic color scheme switching
            background: 'var(--munserv-palette-background-default)',
            color: 'var(--munserv-palette-text-primary)',
            borderRight: 'none',
          },
        }}
        ModalProps={{ keepMounted: true }}
      >
        {logo}
        {drawerContent}
      </Drawer>
    );
  }

  // Desktop: mini drawer (collapsible)
  return (
    <MiniDrawerStyled variant="permanent" open={open}>
      <Toolbar />
      {drawerContent}
    </MiniDrawerStyled>
  );
};

// Re-export drawer width for backward compatibility
export { drawerWidth as SIDEBAR_WIDTH } from '@/theme';
