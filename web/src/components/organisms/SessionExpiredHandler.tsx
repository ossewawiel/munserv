import { useEffect, useState, useRef, useCallback, type FC } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import Typography from '@mui/material/Typography';

import { authEvents } from '@/lib/auth-events';

const REDIRECT_DELAY_MS = 2000;

/**
 * Global handler for session expiration events.
 * Displays a notification and redirects to login after a delay.
 * Should be placed near the root of the app, inside Router context.
 */
export const SessionExpiredHandler: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const queryClient = useQueryClient();

  const [showExpiredMessage, setShowExpiredMessage] = useState(false);
  const hasHandledRef = useRef(false);

  const handleSessionExpired = useCallback(() => {
    // Prevent multiple handlers from showing multiple notifications
    if (hasHandledRef.current) return;

    // Don't show session expired on login page
    if (location.pathname === '/login') return;

    hasHandledRef.current = true;
    setShowExpiredMessage(true);

    // Clear React Query cache
    queryClient.clear();

    // Redirect after delay
    setTimeout(() => {
      navigate('/login', { replace: true });
    }, REDIRECT_DELAY_MS);
  }, [location.pathname, navigate, queryClient]);

  useEffect(() => {
    const unsubscribe = authEvents.subscribe((event) => {
      if (event.type === 'session-expired') {
        handleSessionExpired();
      }
    });

    return unsubscribe;
  }, [handleSessionExpired]);

  // Reset handler and close snackbar when reaching login page
  useEffect(() => {
    if (location.pathname === '/login') {
      setShowExpiredMessage(false);
    } else {
      hasHandledRef.current = false;
    }
  }, [location.pathname]);

  return (
    <Snackbar
      open={showExpiredMessage}
      anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
      sx={{ mt: 2 }}
    >
      <Alert
        severity="warning"
        variant="filled"
        sx={{
          width: '100%',
          alignItems: 'center',
          '& .MuiAlert-icon': {
            color: 'warning.contrastText',
            fontSize: 28,
          },
        }}
      >
        <Typography variant="body1" fontWeight="bold" color="warning.contrastText">
          {t('auth.sessionExpired')}
        </Typography>
        <Typography variant="body2" fontWeight="medium" color="warning.contrastText">
          {t('auth.redirectingToLogin')}
        </Typography>
      </Alert>
    </Snackbar>
  );
};
