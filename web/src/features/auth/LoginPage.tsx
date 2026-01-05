import { type FC, useCallback, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { LoginForm } from '@/components/molecules/LoginForm';
import { useLogin } from './hooks';
import { useAuth } from '@/shared/hooks/useAuth';

interface LocationState {
  from?: { pathname: string };
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
          onSuccess: () => {
            navigate(from, { replace: true });
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
      <h2 className="text-xl font-semibold text-text mb-6">
        {t('auth.login')}
      </h2>
      <LoginForm
        onSubmit={handleSubmit}
        isLoading={loginMutation.isPending}
        error={errorMessage}
      />
    </AuthLayout>
  );
};

export default LoginPage;
