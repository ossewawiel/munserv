import { type FC, useCallback, useEffect } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { LoginForm } from '@/components/molecules/LoginForm';
import { useLogin } from './hooks';
import { useAuth } from '@/shared/hooks/useAuth';
import type { LoginResponse } from './types';

interface LocationState {
  from?: { pathname: string };
}

/**
 * Determines the redirect path based on the login response.
 * Handles super user, onboarding, and regular admin flows.
 */
function getRedirectPath(response: LoginResponse, defaultPath: string): string {
  const { admin } = response.profile;

  // Super user - go to create Pod Chief
  if (admin.role === 'SUPER_USER') {
    return '/bootstrap/create-pod-chief';
  }

  // Regular admin - check onboarding status
  if (admin.onboardingStatus === 'pending') {
    return '/onboarding/change-password';
  }

  if (admin.onboardingStatus === 'password_changed') {
    return '/onboarding/complete-profile';
  }

  // Fully onboarded - go to requested path or dashboard
  return defaultPath;
}

export const LoginPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const { isAuthenticated } = useAuth();
  const loginMutation = useLogin();

  const from = (location.state as LocationState)?.from?.pathname || '/';

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, from]);

  const handleSubmit = useCallback(
    (email: string, password: string) => {
      loginMutation.mutate(
        { email, password },
        {
          onSuccess: (response) => {
            const redirectPath = getRedirectPath(response, from);
            navigate(redirectPath, { replace: true });
          },
        }
      );
    },
    [loginMutation, navigate, from]
  );

  const errorMessage = loginMutation.error
    ? t('auth.loginError')
    : null;

  return (
    <AuthLayout>
      <LoginForm
        onSubmit={handleSubmit}
        isLoading={loginMutation.isPending}
        error={errorMessage}
      />

      <Divider sx={{ my: 3 }}>
        <Typography variant="body2" sx={{
          color: "text.secondary"
        }}>
          {t('auth.or')}
        </Typography>
      </Divider>

      <Box sx={{ textAlign: 'center' }}>
        <Typography variant="body2" gutterBottom sx={{
          color: "text.secondary"
        }}>
          {t('auth.newMember')}
        </Typography>
        <Button
          component={Link}
          to="/register"
          variant="outlined"
          fullWidth
        >
          {t('auth.registerAsNewMember')}
        </Button>
      </Box>
    </AuthLayout>
  );
};

export default LoginPage;
