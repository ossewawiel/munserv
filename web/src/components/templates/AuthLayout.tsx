import { type FC, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { styled, useTheme } from '@mui/material/styles';
import Box from '@mui/material/Box';
import Container from '@mui/material/Container';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import useMediaQuery from '@mui/material/useMediaQuery';

import { useThemeContext } from '@/theme';

interface AuthLayoutProps {
  children: ReactNode;
  /** Optional custom header text (defaults to 'Hi, Welcome Back') */
  header?: string;
  /** Optional custom subtitle text (defaults to 'Enter your credentials to continue') */
  subtitle?: string;
}

// Styled wrapper with vintage map background (Berry AuthWrapper1 pattern)
const AuthWrapper = styled('div')(({ theme }) => ({
  minHeight: '100vh',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  // Content background: cream with optional vintage map overlay
  backgroundColor: 'var(--munserv-palette-tertiaryLight)',
  // Vintage map background image (subtle) - both light and dark modes
  backgroundImage:
    theme.palette.mode === 'dark'
      ? 'linear-gradient(color-mix(in srgb, var(--munserv-palette-background-default) 85%, transparent), color-mix(in srgb, var(--munserv-palette-background-default) 85%, transparent)), url(\'/assets/vintage-map.jpg\')'
      : 'linear-gradient(color-mix(in srgb, var(--munserv-palette-tertiaryLight) 85%, transparent), color-mix(in srgb, var(--munserv-palette-tertiaryLight) 85%, transparent)), url(\'/assets/vintage-map.jpg\')',
  backgroundSize: 'cover',
  backgroundPosition: 'center',
  backgroundAttachment: 'fixed',
  padding: theme.spacing(2),
  [theme.breakpoints.up('sm')]: {
    padding: theme.spacing(6, 2),
  },
}));

export const AuthLayout: FC<AuthLayoutProps> = ({ children, header, subtitle }) => {
  const { t } = useTranslation();
  const theme = useTheme();
  const { colorMode } = useThemeContext();
  const matchDownSM = useMediaQuery(theme.breakpoints.down('sm'));
  const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)');

  // Use custom header/subtitle or defaults
  const headerText = header ?? t('auth.welcomeBack');
  const subtitleText = subtitle ?? t('auth.enterCredentials');

  // Resolve color mode: if 'system', use system preference; otherwise use explicit mode
  const isDarkMode = colorMode === 'system' ? prefersDarkMode : colorMode === 'dark';

  return (
    <AuthWrapper>
      <Container maxWidth="sm">
        <Paper
          elevation={3}
          sx={{
            p: { xs: 3, sm: 4, md: 5 },
            borderRadius: 2,
            maxWidth: { xs: 400, lg: 475 },
            mx: 'auto',
          }}
        >
          {/* Logo and App Name */}
          <Box sx={{ textAlign: 'center', mb: 3 }}>
            <Box
              component="img"
              src={isDarkMode ? '/assets/app-logo-dark.png' : '/assets/app-logo.png'}
              alt={t('common.appName')}
              sx={{ width: '65%', maxWidth: 280, height: 'auto', mb: 1 }}
            />
            <Typography variant="body2" sx={{
              color: "text.secondary"
            }}>
              Municipal Service Admin Portal
            </Typography>
          </Box>

          {/* Welcome message (Berry Login3 pattern) */}
          <Stack
            spacing={0.5}
            sx={{
              alignItems: "center",
              justifyContent: "center",
              mb: 3
            }}>
            <Typography
              color="secondary"
              variant={matchDownSM ? 'h6' : 'h5'}
              sx={{ fontWeight: 600 }}
            >
              {headerText}
            </Typography>
            <Typography
              variant="body2"
              sx={{
                color: "text.secondary",
                textAlign: "center"
              }}>
              {subtitleText}
            </Typography>
          </Stack>

          {/* Form content */}
          {children}
        </Paper>
      </Container>
    </AuthWrapper>
  );
};
