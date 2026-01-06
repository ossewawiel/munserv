import { type FC } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Toolbar from '@mui/material/Toolbar';
import DashboardIcon from '@mui/icons-material/Dashboard';
import AssignmentIcon from '@mui/icons-material/Assignment';
import WhatshotIcon from '@mui/icons-material/Whatshot';
import PeopleIcon from '@mui/icons-material/People';

export const SIDEBAR_WIDTH = 260;

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

  const isSelected = (href: string): boolean => {
    if (href === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(href);
  };

  const drawerContent = (
    <Box sx={{ overflow: 'auto' }}>
      <List>
        {navItems.map((item) => {
          const Icon = item.icon;
          const selected = isSelected(item.href);

          return (
            <ListItemButton
              key={item.href}
              component={Link}
              to={item.href}
              selected={selected}
              onClick={variant === 'temporary' ? onClose : undefined}
              sx={{
                mx: 1,
                my: 0.5,
                borderRadius: 2,
                '&.Mui-selected': {
                  bgcolor: 'secondaryContainer',
                  color: 'onSecondaryContainer',
                  '&:hover': {
                    bgcolor: 'secondaryContainer',
                  },
                  '& .MuiListItemIcon-root': {
                    color: 'secondary.main',
                  },
                },
                '&:hover': {
                  bgcolor: 'action.hover',
                },
              }}
            >
              <ListItemIcon
                sx={{
                  minWidth: 40,
                  color: selected ? 'secondary.main' : 'text.secondary',
                }}
              >
                <Icon />
              </ListItemIcon>
              <ListItemText
                primary={t(item.labelKey)}
                primaryTypographyProps={{
                  fontWeight: selected ? 600 : 400,
                }}
              />
            </ListItemButton>
          );
        })}
      </List>
    </Box>
  );

  return (
    <Drawer
      variant={variant}
      open={open}
      onClose={onClose}
      sx={{
        width: SIDEBAR_WIDTH,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: SIDEBAR_WIDTH,
          boxSizing: 'border-box',
          bgcolor: 'background.paper',
          borderRight: 1,
          borderColor: 'divider',
        },
      }}
    >
      <Toolbar />
      {drawerContent}
    </Drawer>
  );
};
