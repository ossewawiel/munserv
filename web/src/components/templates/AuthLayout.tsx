import { type FC, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { styled, useTheme, useColorScheme } from '@mui/material/styles';
import Box from '@mui/material/Box';
import Container from '@mui/material/Container';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import useMediaQuery from '@mui/material/useMediaQuery';

interface AuthLayoutProps {
  children: ReactNode;
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

export const AuthLayout: FC<AuthLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  const theme = useTheme();
  const { mode } = useColorScheme();
  const matchDownSM = useMediaQuery(theme.breakpoints.down('sm'));

  // Determine if we're in dark mode (handle 'system' mode too)
  const isDarkMode = mode === 'dark';

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
            <Typography variant="body2" color="text.secondary">
              Municipal Service Admin Portal
            </Typography>
          </Box>

          {/* Welcome message (Berry Login3 pattern) */}
          <Stack alignItems="center" justifyContent="center" spacing={0.5} sx={{ mb: 3 }}>
            <Typography
              color="secondary"
              variant={matchDownSM ? 'h6' : 'h5'}
              sx={{ fontWeight: 600 }}
            >
              {t('auth.welcomeBack')}
            </Typography>
            <Typography
              variant="body2"
              color="text.secondary"
              textAlign="center"
            >
              {t('auth.enterCredentials')}
            </Typography>
          </Stack>

          {/* Form content */}
          {children}
        </Paper>
      </Container>
    </AuthWrapper>
  );
};
