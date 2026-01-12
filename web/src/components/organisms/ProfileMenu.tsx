import {
  type FC,
  useState,
  useEffect,
  useCallback,
  useMemo,
} from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useTheme } from '@mui/material/styles';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Chip from '@mui/material/Chip';
import ClickAwayListener from '@mui/material/ClickAwayListener';
import Divider from '@mui/material/Divider';
import Fade from '@mui/material/Fade';
import List from '@mui/material/List';
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
import TranslateIcon from '@mui/icons-material/Translate';
import PersonIcon from '@mui/icons-material/Person';

import { useLogout } from '@/features/auth/hooks';
import { useThemeContext, commonAvatar, mediumAvatar } from '@/theme';
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
  const theme = useTheme();
  const navigate = useNavigate();
  const logout = useLogout();
  const { colorMode, setColorMode } = useThemeContext();

  const [anchorEl, setAnchorEl] = useState<HTMLDivElement | null>(null);
  const open = Boolean(anchorEl);

  const admin = useMemo(() => getAdminProfile(), []);
  const userName = admin?.name ?? 'Admin';
  const greetingKey = getTimeOfDayKey();

  const handleToggle = useCallback(
    (event: React.MouseEvent<HTMLDivElement>) => {
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
      {/* Profile Trigger - Berry style Chip with Avatar */}
      <Chip
        sx={{
          height: '48px',
          alignItems: 'center',
          borderRadius: '27px',
          transition: 'all .2s ease-in-out',
          borderColor:
            theme.palette.mode === 'dark'
              ? 'var(--munserv-palette-surfaceContainerHigh)'
              : 'var(--munserv-palette-primary-light)',
          backgroundColor:
            theme.palette.mode === 'dark'
              ? 'var(--munserv-palette-surfaceContainerHigh)'
              : 'var(--munserv-palette-primary-light)',
          '&[aria-controls="profile-menu"], &:hover': {
            borderColor: 'var(--munserv-palette-primary-main)',
            background: 'var(--munserv-palette-primary-main)',
            color: 'var(--munserv-palette-primary-contrastText)',
            '& svg': {
              color: 'var(--munserv-palette-primary-contrastText)',
            },
          },
          '& .MuiChip-label': {
            lineHeight: 0,
          },
        }}
        icon={
          <Avatar
            sx={{
              ...commonAvatar,
              ...mediumAvatar,
              margin: '8px 0 8px 8px !important',
              cursor: 'pointer',
              bgcolor: 'var(--munserv-palette-primary-main)',
              color: 'var(--munserv-palette-primary-contrastText)',
            }}
            aria-hidden="true"
          >
            <PersonIcon fontSize="small" />
          </Avatar>
        }
        label={
          <SettingsIcon
            sx={{
              fontSize: '24px',
              color: 'var(--munserv-palette-primary-main)',
            }}
          />
        }
        variant="outlined"
        aria-controls={open ? 'profile-menu' : undefined}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label={t('profile.menuTrigger', 'Profile menu')}
        onClick={handleToggle}
        color="primary"
      />

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

                    <Divider />

                    {/* Settings Card */}
                    <Box sx={{ p: 2 }}>
                      <Card
                        sx={{
                          bgcolor:
                            theme.palette.mode === 'dark'
                              ? 'var(--munserv-palette-surfaceContainerHigh)'
                              : 'var(--munserv-palette-primary-light)',
                        }}
                      >
                        <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
                          <Stack spacing={2}>
                            {/* Mood Toggle */}
                            <Box>
                              <Typography
                                variant="subtitle2"
                                color="text.secondary"
                                sx={{ mb: 1 }}
                              >
                                {t('profile.mood', 'Mood')}
                              </Typography>
                              <ToggleButtonGroup
                                value={colorMode}
                                exclusive
                                onChange={handleMoodChange}
                                aria-label={t('profile.mood', 'Mood')}
                                size="small"
                                fullWidth
                              >
                                <ToggleButton
                                  value="light"
                                  aria-label={t('profile.moodLight', 'Light')}
                                >
                                  <LightModeIcon sx={{ mr: 0.5 }} fontSize="small" />
                                  {t('profile.moodLight', 'Light')}
                                </ToggleButton>
                                <ToggleButton
                                  value="dark"
                                  aria-label={t('profile.moodDark', 'Dark')}
                                >
                                  <DarkModeIcon sx={{ mr: 0.5 }} fontSize="small" />
                                  {t('profile.moodDark', 'Dark')}
                                </ToggleButton>
                                <ToggleButton
                                  value="system"
                                  aria-label={t('profile.moodSystem', 'System')}
                                >
                                  <SettingsBrightnessIcon
                                    sx={{ mr: 0.5 }}
                                    fontSize="small"
                                  />
                                  {t('profile.moodSystem', 'System')}
                                </ToggleButton>
                              </ToggleButtonGroup>
                            </Box>

                            {/* Language Selection */}
                            <Box>
                              <Typography
                                variant="subtitle2"
                                color="text.secondary"
                                sx={{ mb: 1 }}
                              >
                                {t('profile.language', 'Language')}
                              </Typography>
                              <Stack direction="row" spacing={1}>
                                {SUPPORTED_LANGUAGES.map((lng) => (
                                  <Chip
                                    key={lng}
                                    label={LANGUAGE_NAMES[lng]}
                                    icon={<TranslateIcon />}
                                    variant={
                                      i18n.language === lng ? 'filled' : 'outlined'
                                    }
                                    color={
                                      i18n.language === lng ? 'primary' : 'default'
                                    }
                                    onClick={() => handleLanguageSelect(lng)}
                                    sx={{ cursor: 'pointer' }}
                                  />
                                ))}
                              </Stack>
                            </Box>
                          </Stack>
                        </CardContent>
                      </Card>
                    </Box>

                    <Divider />

                    {/* Logout Button */}
                    <List
                      component="nav"
                      sx={{
                        width: '100%',
                        bgcolor: 'background.paper',
                        '& .MuiListItemButton-root': {
                          borderRadius: 1,
                          mx: 1,
                          mb: 1,
                        },
                      }}
                    >
                      <ListItemButton
                        onClick={handleLogout}
                        disabled={logout.isPending}
                        aria-label={t('auth.logout', 'Logout')}
                      >
                        <ListItemIcon>
                          <LogoutIcon />
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
