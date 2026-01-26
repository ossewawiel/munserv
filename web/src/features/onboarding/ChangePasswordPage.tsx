import { type FC, useCallback, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { AxiosError } from 'axios';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { useAuth } from '@/shared/hooks/useAuth';
import { ChangePasswordForm } from './components/ChangePasswordForm';
import { useChangePassword } from './hooks';

interface ApiError {
  code?: string;
  message?: string;
}

export const ChangePasswordPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { isAuthenticated, admin } = useAuth();
  const changePasswordMutation = useChangePassword();

  // Redirect if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Redirect if password already changed
  useEffect(() => {
    if (admin && admin.onboardingStatus !== 'pending') {
      if (admin.onboardingStatus === 'password_changed') {
        navigate('/onboarding/complete-profile', { replace: true });
      } else {
        navigate('/', { replace: true });
      }
    }
  }, [admin, navigate]);

  const handleSubmit = useCallback(
    (newPassword: string) => {
      changePasswordMutation.mutate(
        { newPassword },
        {
          onSuccess: (response) => {
            if (response.requiresProfileCompletion) {
              navigate('/onboarding/complete-profile', { replace: true });
            } else {
              navigate('/', { replace: true });
            }
          },
        }
      );
    },
    [changePasswordMutation, navigate]
  );

  const getErrorMessage = (): string | null => {
    if (!changePasswordMutation.error) return null;

    const error = changePasswordMutation.error;
    if (error instanceof AxiosError && error.response?.data) {
      const apiError = error.response.data as ApiError;
      if (apiError.code === 'validation_error') {
        return apiError.message ?? t('onboarding.changePasswordError');
      }
      if (apiError.code === 'invalid_step') {
        return apiError.message ?? t('onboarding.changePasswordError');
      }
    }

    return t('onboarding.changePasswordError');
  };

  return (
    <AuthLayout
      header={t('onboarding.changePassword')}
      subtitle={t('onboarding.changePasswordDescription')}
    >
      <ChangePasswordForm
        onSubmit={handleSubmit}
        isLoading={changePasswordMutation.isPending}
        error={getErrorMessage()}
      />
    </AuthLayout>
  );
};

export default ChangePasswordPage;
