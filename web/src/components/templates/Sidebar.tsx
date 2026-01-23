import { type FC, useMemo } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Badge from '@mui/material/Badge';
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
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import AnalyticsIcon from '@mui/icons-material/Analytics';
import AssignmentIcon from '@mui/icons-material/Assignment';
import BadgeIcon from '@mui/icons-material/Badge';
import DashboardIcon from '@mui/icons-material/Dashboard';
import EmailIcon from '@mui/icons-material/Email';
import PeopleIcon from '@mui/icons-material/People';
import SettingsIcon from '@mui/icons-material/Settings';
import WhatshotIcon from '@mui/icons-material/Whatshot';

import { drawerWidth } from '@/theme';
import { MiniDrawerStyled } from './MiniDrawerStyled';
import { useUnreadCount } from '@/features/messages/hooks';
import { useAuth } from '@/shared/hooks/useAuth';
import { hasPermission, type AdminRole } from '@/shared/types/admin';

/** Get the color for selected/hovered items based on theme mode */
const getItemColor = (isDarkMode: boolean): string =>
  isDarkMode ? 'secondary.main' : 'secondary.dark';

interface NavItem {
  labelKey: string;
  href: string;
  icon: React.ElementType;
  badgeKey?: 'unreadMessages';
  /** Minimum role required to see this nav item */
  requiredRole?: AdminRole;
  /** Child items for grouped navigation */
  children?: NavItem[];
}

const navItems: NavItem[] = [
  { labelKey: 'nav.dashboard', href: '/', icon: DashboardIcon },
  { labelKey: 'nav.issues', href: '/issues', icon: AssignmentIcon },
  // Reports section (visible to all)
  {
    labelKey: 'nav.reports',
    href: '/reports',
    icon: AnalyticsIcon,
    children: [{ labelKey: 'nav.heatReport', href: '/reports/heat', icon: WhatshotIcon }],
  },
  { labelKey: 'nav.members', href: '/members', icon: PeopleIcon },
  {
    labelKey: 'nav.messages',
    href: '/messages',
    icon: EmailIcon,
    badgeKey: 'unreadMessages',
  },
  { labelKey: 'nav.groundAdmins', href: '/ground-admins', icon: BadgeIcon },
  // Sector Chief and above
  {
    labelKey: 'nav.adminManagement',
    href: '/admin-management',
    icon: AdminPanelSettingsIcon,
    requiredRole: 'sector_chief',
  },
  {
    labelKey: 'nav.sectorSettings',
    href: '/settings/sector',
    icon: SettingsIcon,
    requiredRole: 'sector_chief',
  },
  // Ward Chief and above
  {
    labelKey: 'nav.wardSettings',
    href: '/settings/ward',
    icon: SettingsIcon,
    requiredRole: 'ward_chief',
  },
  // Pod Chief and above
  {
    labelKey: 'nav.podSettings',
    href: '/settings/pod',
    icon: SettingsIcon,
    requiredRole: 'pod_chief',
  },
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
  const { data: unreadCount = 0 } = useUnreadCount();
  const { admin } = useAuth();
  const userRole = admin?.role ?? 'sector_admin';

  // Filter nav items based on user role
  const visibleNavItems = useMemo(() => {
    const filterByRole = (items: NavItem[]): NavItem[] => {
      return items
        .filter((item) => !item.requiredRole || hasPermission(userRole, item.requiredRole))
        .map((item) => {
          if (item.children) {
            return { ...item, children: filterByRole(item.children) };
          }
          return item;
        });
    };

    // Flatten items with children for simpler rendering in MVP
    // Future: implement collapsible menu groups
    const flattenItems = (items: NavItem[]): NavItem[] => {
      return items.flatMap((item) => {
        if (item.children && item.children.length > 0) {
          return item.children;
        }
        return [item];
      });
    };

    return flattenItems(filterByRole(navItems));
  }, [userRole]);

  const isSelected = (href: string): boolean => {
    if (href === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(href);
  };

  const getBadgeCount = (badgeKey?: NavItem['badgeKey']): number => {
    if (badgeKey === 'unreadMessages') {
      return unreadCount;
    }
    return 0;
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
        {visibleNavItems.map((item) => {
          const Icon = item.icon;
          const selected = isSelected(item.href);
          const badgeCount = getBadgeCount(item.badgeKey);

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
                {badgeCount > 0 ? (
                  <Badge
                    badgeContent={badgeCount}
                    color="error"
                    max={99}
                    sx={{
                      '& .MuiBadge-badge': {
                        fontSize: '0.6rem',
                        height: 16,
                        minWidth: 16,
                      },
                    }}
                  >
                    <Icon />
                  </Badge>
                ) : (
                  <Icon />
                )}
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
