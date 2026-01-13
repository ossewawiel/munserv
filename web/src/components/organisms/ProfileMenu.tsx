import {
  type FC,
  useState,
  useEffect,
  useCallback,
  useMemo,
} from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import ButtonBase from '@mui/material/ButtonBase';
import ClickAwayListener from '@mui/material/ClickAwayListener';
import Divider from '@mui/material/Divider';
import Fade from '@mui/material/Fade';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Paper from '@mui/material/Paper';
import Popper from '@mui/material/Popper';
import Stack from '@mui/material/Stack';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import Typography from '@mui/material/Typography';
import SettingsIcon from '@mui/icons-material/Settings';
import LogoutIcon from '@mui/icons-material/Logout';
import LightModeIcon from '@mui/icons-material/LightMode';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import SettingsBrightnessIcon from '@mui/icons-material/SettingsBrightness';
import LanguageIcon from '@mui/icons-material/Language';
import PersonIcon from '@mui/icons-material/Person';

import { useLogout } from '@/features/auth/hooks';
import { useThemeContext } from '@/theme';
import { SUPPORTED_LANGUAGES, LANGUAGE_NAMES } from '@/lib/i18n';
import type { ColorMode } from '@/theme/types';

interface AdminProfile {
  id: string;
  name: string;
  email: string;
}

/**
 * Get time-of-day greeting based on current hour
 */
function getTimeOfDayKey(): 'morning' | 'afternoon' | 'evening' {
  const hour = new Date().getHours();
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}

/**
 * Get admin profile from localStorage
 */
function getAdminProfile(): AdminProfile | null {
  try {
    const adminJson = localStorage.getItem('admin');
    if (adminJson) {
      return JSON.parse(adminJson) as AdminProfile;
    }
  } catch {
    // Silently fail if JSON is invalid
  }
  return null;
}

export const ProfileMenu: FC = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const logout = useLogout();
  const { colorMode, setColorMode } = useThemeContext();

  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const open = Boolean(anchorEl);

  const admin = useMemo(() => getAdminProfile(), []);
  const userName = admin?.name ?? 'Admin';
  const greetingKey = getTimeOfDayKey();

  const handleToggle = useCallback(
    (event: React.MouseEvent<HTMLButtonElement>) => {
      setAnchorEl(anchorEl ? null : event.currentTarget);
    },
    [anchorEl]
  );

  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const handleKeyDown = useCallback((event: KeyboardEvent) => {
    if (event.key === 'Escape') {
      setAnchorEl(null);
    }
  }, []);

  // Handle Escape key
  useEffect(() => {
    if (open) {
      document.addEventListener('keydown', handleKeyDown);
      return () => document.removeEventListener('keydown', handleKeyDown);
    }
  }, [open, handleKeyDown]);

  const handleMoodChange = useCallback(
    (_event: React.MouseEvent<HTMLElement>, newMode: ColorMode | null) => {
      if (newMode !== null) {
        setColorMode(newMode);
      }
    },
    [setColorMode]
  );

  const handleLanguageSelect = useCallback(
    (lng: string) => {
      i18n.changeLanguage(lng);
      setAnchorEl(null);
    },
    [i18n]
  );

  const handleLogout = useCallback(() => {
    logout.mutate(undefined, {
      onSuccess: () => {
        navigate('/login');
      },
      onError: () => {
        // Clear localStorage and redirect even on error
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('admin');
        navigate('/login');
      },
    });
  }, [logout, navigate]);

  return (
    <>
      {/* Profile Trigger - Berry style compact button with avatar and settings icon */}
      <ButtonBase
        sx={{
          borderRadius: '27px',
          overflow: 'hidden',
          ml: 1,
        }}
        aria-controls={open ? 'profile-menu' : undefined}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label={t('profile.menuTrigger', 'Profile menu')}
        onClick={handleToggle}
      >
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            height: '34px',
            borderRadius: '27px',
            border: '1px solid',
            transition: 'all .2s ease-in-out',
            borderColor: open
              ? 'var(--munserv-palette-primary-main)'
              : 'var(--munserv-palette-primary-light)',
            bgcolor: open
              ? 'var(--munserv-palette-primary-main)'
              : 'var(--munserv-palette-primary-light)',
            '&:hover': {
              borderColor: 'var(--munserv-palette-primary-main)',
              bgcolor: 'var(--munserv-palette-primary-main)',
              '& .profile-avatar': {
                bgcolor: 'var(--munserv-palette-primary-contrastText)',
                color: 'var(--munserv-palette-primary-main)',
              },
              '& .profile-settings-icon': {
                color: 'var(--munserv-palette-primary-contrastText)',
              },
            },
          }}
        >
          {/* Avatar - Round with primary background */}
          <Avatar
            className="profile-avatar"
            sx={{
              width: 26,
              height: 26,
              ml: '4px',
              fontSize: '1rem',
              transition: 'all .2s ease-in-out',
              bgcolor: open
                ? 'var(--munserv-palette-primary-contrastText)'
                : 'var(--munserv-palette-primary-main)',
              color: open
                ? 'var(--munserv-palette-primary-main)'
                : 'var(--munserv-palette-primary-contrastText)',
            }}
            aria-hidden="true"
          >
            <PersonIcon sx={{ fontSize: '1rem' }} />
          </Avatar>
          {/* Settings icon */}
          <SettingsIcon
            className="profile-settings-icon"
            sx={{
              fontSize: '1.25rem',
              mx: '6px',
              transition: 'all .2s ease-in-out',
              color: open
                ? 'var(--munserv-palette-primary-contrastText)'
                : 'var(--munserv-palette-primary-main)',
            }}
          />
        </Box>
      </ButtonBase>

      {/* Profile Menu Popper */}
      <Popper
        placement="bottom-end"
        open={open}
        anchorEl={anchorEl}
        role={undefined}
        transition
        disablePortal
        modifiers={[
          {
            name: 'offset',
            options: {
              offset: [0, 14],
            },
          },
        ]}
      >
        {({ TransitionProps }) => (
          <ClickAwayListener onClickAway={handleClose}>
            <Fade {...TransitionProps} timeout={350}>
              <Paper
                id="profile-menu"
                elevation={16}
                sx={{
                  borderRadius: 2,
                  overflow: 'hidden',
                  minWidth: 280,
                  maxWidth: 350,
                }}
              >
                {open && (
                  <>
                    {/* Greeting Header */}
                    <Box sx={{ p: 2, pb: 1.5 }}>
                      <Stack spacing={0.5}>
                        <Typography
                          variant="h6"
                          color="text.secondary"
                          sx={{ fontWeight: 400 }}
                        >
                          {t(`profile.greeting.${greetingKey}`)},
                        </Typography>
                        <Typography variant="h5" sx={{ fontWeight: 600 }}>
                          {userName}
                        </Typography>
                      </Stack>
                    </Box>

                    {/* Settings List - Berry style with consistent layout */}
                    <Box sx={{ p: 2, pt: 0 }}>
                      <List
                        component="nav"
                        sx={{
                          width: '100%',
                          maxWidth: 350,
                          minWidth: 300,
                          bgcolor: 'background.paper',
                          borderRadius: '10px',
                          '& .MuiListItemButton-root': {
                            mt: 0.5,
                          },
                        }}
                      >
                        {/* Theme Mood - Switch style like reference */}
                        <ListItem>
                          <ListItemIcon sx={{ minWidth: 36 }}>
                            {colorMode === 'dark' ? (
                              <DarkModeIcon sx={{ fontSize: '1.25rem' }} />
                            ) : colorMode === 'system' ? (
                              <SettingsBrightnessIcon sx={{ fontSize: '1.25rem' }} />
                            ) : (
                              <LightModeIcon sx={{ fontSize: '1.25rem' }} />
                            )}
                          </ListItemIcon>
                          <ListItemText
                            primary={
                              <Typography variant="body2">
                                {t('profile.mood', 'Mood')}
                              </Typography>
                            }
                          />
                          <ToggleButtonGroup
                            value={colorMode}
                            exclusive
                            onChange={handleMoodChange}
                            aria-label={t('profile.mood', 'Mood')}
                            size="small"
                          >
                            <ToggleButton
                              value="light"
                              aria-label={t('profile.moodLight', 'Light')}
                              sx={{ px: 1, py: 0.25 }}
                            >
                              <LightModeIcon sx={{ fontSize: '1rem' }} />
                            </ToggleButton>
                            <ToggleButton
                              value="dark"
                              aria-label={t('profile.moodDark', 'Dark')}
                              sx={{ px: 1, py: 0.25 }}
                            >
                              <DarkModeIcon sx={{ fontSize: '1rem' }} />
                            </ToggleButton>
                            <ToggleButton
                              value="system"
                              aria-label={t('profile.moodSystem', 'System')}
                              sx={{ px: 1, py: 0.25 }}
                            >
                              <SettingsBrightnessIcon sx={{ fontSize: '1rem' }} />
                            </ToggleButton>
                          </ToggleButtonGroup>
                        </ListItem>

                        {/* Language - Current selection with toggle */}
                        <ListItem>
                          <ListItemIcon sx={{ minWidth: 36 }}>
                            <LanguageIcon sx={{ fontSize: '1.25rem' }} />
                          </ListItemIcon>
                          <ListItemText
                            primary={
                              <Typography variant="body2">
                                {t('profile.language', 'Language')}
                              </Typography>
                            }
                          />
                          <ToggleButtonGroup
                            value={i18n.language}
                            exclusive
                            onChange={(_e, lng: string | null) => {
                              if (lng) handleLanguageSelect(lng);
                            }}
                            aria-label={t('profile.language', 'Language')}
                            size="small"
                          >
                            {SUPPORTED_LANGUAGES.map((lng) => (
                              <ToggleButton
                                key={lng}
                                value={lng}
                                aria-label={LANGUAGE_NAMES[lng]}
                                sx={{ px: 1.5, py: 0.25, textTransform: 'uppercase' }}
                              >
                                {lng}
                              </ToggleButton>
                            ))}
                          </ToggleButtonGroup>
                        </ListItem>

                        <Divider sx={{ my: 1 }} />

                        {/* Logout Button */}
                        <ListItemButton
                          onClick={handleLogout}
                          disabled={logout.isPending}
                          aria-label={t('auth.logout', 'Logout')}
                          sx={{ borderRadius: '8px' }}
                        >
                          <ListItemIcon sx={{ minWidth: 36 }}>
                            <LogoutIcon sx={{ fontSize: '1.25rem' }} />
                          </ListItemIcon>
                          <ListItemText
                            primary={
                              <Typography variant="body2">
                                {logout.isPending
                                  ? t('common.loading', 'Loading...')
                                  : t('auth.logout', 'Logout')}
                              </Typography>
                            }
                          />
                        </ListItemButton>
                      </List>
                    </Box>
                  </>
                )}
              </Paper>
            </Fade>
          </ClickAwayListener>
        )}
      </Popper>
    </>
  );
};
