import { type FC, useMemo, useState, useCallback, Fragment } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Badge from '@mui/material/Badge';
import Box from '@mui/material/Box';
import Collapse from '@mui/material/Collapse';
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
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import GridViewIcon from '@mui/icons-material/GridView';
import GroupsIcon from '@mui/icons-material/Groups';
import PeopleIcon from '@mui/icons-material/People';
import SettingsIcon from '@mui/icons-material/Settings';
import WhatshotIcon from '@mui/icons-material/Whatshot';

import { drawerWidth } from '@/theme';
import { MiniDrawerStyled } from './MiniDrawerStyled';
import { useUnreadCount } from '@/features/messages/hooks';
import { useAuth } from '@/shared/hooks/useAuth';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
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
  /** Maximum role - item hidden for higher roles (used to hide sector-level items from pod chief) */
  maxRole?: AdminRole;
  /** Child items for grouped navigation */
  children?: NavItem[];
  /** Whether children should be shown in a collapsible submenu */
  collapsible?: boolean;
  /** Dynamic children that are computed at runtime */
  dynamicChildren?: boolean;
}

/**
 * Base navigation items for sector-level admins (sector_admin, sector_chief)
 * These items are shown to users below pod_admin level
 */
const sectorNavItems: NavItem[] = [
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
  // Sector Chief only (not pod level)
  {
    labelKey: 'nav.adminManagement',
    href: '/admin-management',
    icon: AdminPanelSettingsIcon,
    requiredRole: 'sector_chief',
    maxRole: 'ward_chief', // Hide from ward_chief and above
  },
  {
    labelKey: 'nav.sectorSettings',
    href: '/settings/sector',
    icon: SettingsIcon,
    requiredRole: 'sector_chief',
    maxRole: 'ward_chief', // Hide from ward_chief and above
  },
  // Ward Chief only (not pod level)
  {
    labelKey: 'nav.wardSettings',
    href: '/settings/ward',
    icon: SettingsIcon,
    requiredRole: 'ward_chief',
    maxRole: 'pod_admin', // Hide from pod_admin and above
  },
];

/**
 * Navigation items for Pod Chief role
 * Per W10 acceptance criteria:
 * - Dashboard (main pod dashboard)
 * - Ward/Sector Dashboards (separate dropdown, appears after setup) - W13
 * - Pod Administrators (conditional on setup complete) - W14
 * - Reports (dropdown with General + ward/sector reports) - W20
 * - Messages - W17
 * - Pod Settings - W18/W19
 */
const podChiefNavItems: NavItem[] = [
  // Main dashboard - always visible
  {
    labelKey: 'nav.dashboard',
    href: '/',
    icon: DashboardIcon,
  },
  // Ward/Sector Dashboards - separate dropdown, appears only after setup (W13)
  // This is dynamically shown/hidden and populated based on pod setup
  {
    labelKey: 'nav.wardDashboards', // or sectorDashboards - label set dynamically
    href: '/dashboards', // Parent path for area dashboards
    icon: GridViewIcon,
    collapsible: true,
    dynamicChildren: true, // Wards/sectors added dynamically
    children: [], // Populated dynamically with ward/sector items
  },
  // Pod Administrators - conditional on setup complete (W14)
  {
    labelKey: 'nav.podAdministrators',
    href: '/pod-administrators',
    icon: GroupsIcon,
  },
  // Reports - dropdown with General + ward/sector reports (W20)
  {
    labelKey: 'nav.reports',
    href: '/reports',
    icon: AnalyticsIcon,
    collapsible: true,
    dynamicChildren: true, // Ward/sector reports added dynamically
    children: [
      { labelKey: 'nav.generalReports', href: '/reports/general', icon: AnalyticsIcon },
    ],
  },
  // Messages (W17)
  {
    labelKey: 'nav.messages',
    href: '/messages',
    icon: EmailIcon,
    badgeKey: 'unreadMessages',
  },
  // Pod Settings (W18/W19)
  {
    labelKey: 'nav.podSettings',
    href: '/settings/pod',
    icon: SettingsIcon,
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
  const podSetup = usePodSetup();

  // Track which submenus are expanded
  const [expandedMenus, setExpandedMenus] = useState<Record<string, boolean>>({});

  const toggleSubmenu = useCallback((href: string) => {
    setExpandedMenus((prev) => ({ ...prev, [href]: !prev[href] }));
  }, []);

  // Check if user is at pod level (pod_admin or pod_chief)
  const isPodLevel = hasPermission(userRole, 'pod_admin');

  // Build navigation items based on role
  const visibleNavItems = useMemo(() => {
    // For pod-level users, use pod-specific navigation
    if (isPodLevel) {
      const hasWards = podSetup.status && podSetup.status.wards.length > 0;

      const items = podChiefNavItems
        .map((item) => {
          // Ward/Sector Dashboards dropdown (W13) - only show if areas configured
          if (item.href === '/dashboards') {
            if (!podSetup.showAreaDashboards || !podSetup.status) {
              return null; // Hide if no areas configured
            }

            // Build children from wards and sectors
            const areaChildren: NavItem[] = [
              ...podSetup.status.wards.map((ward) => ({
                labelKey: ward.name, // Direct name
                href: `/dashboard/ward/${ward.id}`,
                icon: GridViewIcon,
              })),
              ...podSetup.status.sectors.map((sector) => ({
                labelKey: sector.name, // Direct name
                href: `/dashboard/sector/${sector.id}`,
                icon: GridViewIcon,
              })),
            ];

            // Use "Ward Dashboards" or "Sector Dashboards" label based on what's configured
            const labelKey = hasWards ? 'nav.wardDashboards' : 'nav.sectorDashboards';

            return {
              ...item,
              labelKey,
              children: areaChildren,
            };
          }

          // Reports dropdown (W20) - add General + ward/sector reports
          if (item.href === '/reports' && item.dynamicChildren && podSetup.status) {
            const reportChildren: NavItem[] = [
              // General (pod-wide) reports first
              { labelKey: 'nav.generalReports', href: '/reports/general', icon: AnalyticsIcon },
            ];

            // Add ward reports if wards exist
            podSetup.status.wards.forEach((ward) => {
              reportChildren.push({
                labelKey: ward.name, // Direct name
                href: `/reports/ward/${ward.id}`,
                icon: AnalyticsIcon,
              });
            });

            // Add sector reports if sectors exist
            podSetup.status.sectors.forEach((sector) => {
              reportChildren.push({
                labelKey: sector.name, // Direct name
                href: `/reports/sector/${sector.id}`,
                icon: AnalyticsIcon,
              });
            });

            return {
              ...item,
              children: reportChildren,
            };
          }

          return item;
        })
        .filter((item): item is NavItem => item !== null);

      // Filter out Pod Administrators if setup is not complete
      return items.filter((item) => {
        if (item.href === '/pod-administrators') {
          return podSetup.showPodAdmins;
        }
        return true;
      });
    }

    // For sector/ward level users, use sector navigation
    const filterByRole = (items: NavItem[]): NavItem[] => {
      return items
        .filter((item) => {
          // Check minimum role requirement
          if (item.requiredRole && !hasPermission(userRole, item.requiredRole)) {
            return false;
          }
          // Check maximum role - hide from higher roles
          if (item.maxRole && hasPermission(userRole, item.maxRole)) {
            return false;
          }
          return true;
        })
        .map((item) => {
          if (item.children) {
            return { ...item, children: filterByRole(item.children) };
          }
          return item;
        });
    };

    // Flatten non-collapsible items with children for simpler rendering
    const flattenItems = (items: NavItem[]): NavItem[] => {
      return items.flatMap((item) => {
        if (item.children && item.children.length > 0 && !item.collapsible) {
          return item.children;
        }
        return [item];
      });
    };

    return flattenItems(filterByRole(sectorNavItems));
  }, [userRole, isPodLevel, podSetup]);

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

  /**
   * Get the translated label for a nav item.
   * If the labelKey doesn't start with 'nav.' it's a direct name (e.g., ward/sector names).
   */
  const getLabel = (labelKey: string): string => {
    if (labelKey.startsWith('nav.') || labelKey.startsWith('podChief.')) {
      return t(labelKey);
    }
    return labelKey; // Direct name for dynamic items
  };

  /**
   * Render a single nav item button
   */
  const renderNavItem = (item: NavItem, isChild = false) => {
    const Icon = item.icon;
    const selected = isSelected(item.href);
    const badgeCount = getBadgeCount(item.badgeKey);
    const hasChildren = item.collapsible && item.children && item.children.length > 0;
    const isExpanded = expandedMenus[item.href];

    const handleClick = () => {
      if (hasChildren && open) {
        toggleSubmenu(item.href);
      } else if (variant === 'temporary') {
        onClose();
      }
    };

    const listItem = (
      <ListItemButton
        component={hasChildren ? 'div' : Link}
        to={hasChildren ? undefined : item.href}
        selected={selected}
        onClick={handleClick}
        sx={{
          minHeight: 44,
          borderRadius: 2,
          mb: 0.5,
          px: open ? 2 : 1.5,
          pl: isChild && open ? 4 : open ? 2 : 1.5, // Indent children
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
          <>
            <ListItemText
              primary={getLabel(item.labelKey)}
              slotProps={{
                primary: {
                  fontWeight: selected ? 600 : 400,
                  fontSize: isChild ? '0.8125rem' : '0.875rem',
                },
              }}
            />
            {hasChildren && (isExpanded ? <ExpandLess /> : <ExpandMore />)}
          </>
        )}
      </ListItemButton>
    );

    // Wrap in tooltip when drawer is collapsed
    if (!open && variant === 'permanent') {
      return (
        <Tooltip key={item.href} title={getLabel(item.labelKey)} placement="right" arrow>
          {listItem}
        </Tooltip>
      );
    }

    return listItem;
  };

  const drawerContent = (
    <Box sx={{ overflow: 'auto', mt: open ? 0 : 2 }}>
      <List sx={{ px: open ? 2 : 0.5 }}>
        {visibleNavItems.map((item) => {
          const hasChildren = item.collapsible && item.children && item.children.length > 0;
          const isExpanded = expandedMenus[item.href];

          return (
            <Fragment key={item.href}>
              {renderNavItem(item)}
              {hasChildren && open && (
                <Collapse in={isExpanded} timeout="auto" unmountOnExit>
                  <List component="div" disablePadding>
                    {item.children!.map((child) => (
                      <Fragment key={child.href}>
                        {renderNavItem(child, true)}
                      </Fragment>
                    ))}
                  </List>
                </Collapse>
              )}
            </Fragment>
          );
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
