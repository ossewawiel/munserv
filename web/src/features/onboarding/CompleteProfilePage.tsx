import { type FC, type FormEvent, useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { AxiosError } from 'axios';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { Button } from '@/components/atoms/Button';
import { Input } from '@/components/atoms/Input';
import { useAuth } from '@/shared/hooks/useAuth';
import { useCompleteProfile } from './hooks';

interface ApiError {
  code?: string;
  message?: string;
}

export const CompleteProfilePage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { isAuthenticated, admin } = useAuth();
  const completeProfileMutation = useCompleteProfile();

  const [displayName, setDisplayName] = useState(admin?.displayName ?? '');

  // Redirect if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  // Redirect if not at the profile completion step
  useEffect(() => {
    if (admin) {
      if (admin.onboardingStatus === 'pending') {
        navigate('/onboarding/change-password', { replace: true });
      } else if (admin.onboardingStatus !== 'password_changed') {
        navigate('/', { replace: true });
      }
    }
  }, [admin, navigate]);

  const handleSubmit = useCallback(
    (e: FormEvent) => {
      e.preventDefault();
      completeProfileMutation.mutate(
        { displayName: displayName.trim() || undefined },
        {
          onSuccess: () => {
            navigate('/', { replace: true });
          },
        }
      );
    },
    [completeProfileMutation, displayName, navigate]
  );

  const handleSkip = useCallback(() => {
    completeProfileMutation.mutate(
      {},
      {
        onSuccess: () => {
          navigate('/', { replace: true });
        },
      }
    );
  }, [completeProfileMutation, navigate]);

  const getErrorMessage = (): string | null => {
    if (!completeProfileMutation.error) return null;

    const error = completeProfileMutation.error;
    if (error instanceof AxiosError && error.response?.data) {
      const apiError = error.response.data as ApiError;
      if (apiError.code === 'validation_error') {
        return apiError.message ?? t('onboarding.profileError');
      }
      if (apiError.code === 'invalid_step') {
        return apiError.message ?? t('onboarding.profileError');
      }
    }

    return t('onboarding.profileError');
  };

  return (
    <AuthLayout
      header={t('onboarding.completeProfile')}
      subtitle={t('onboarding.completeProfileDescription')}
    >
      <Box
        component="form"
        onSubmit={handleSubmit}
        sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}
      >
        {getErrorMessage() && (
          <Alert severity="error" variant="outlined">
            {getErrorMessage()}
          </Alert>
        )}

        <Input
          label={t('onboarding.displayName')}
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          placeholder={admin?.displayName}
          disabled={completeProfileMutation.isPending}
          helperText={t('onboarding.knownAsHelper')}
        />

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <Button
            type="submit"
            fullWidth
            isLoading={completeProfileMutation.isPending}
          >
            {t('onboarding.complete')}
          </Button>

          <Button
            type="button"
            variant="ghost"
            fullWidth
            onClick={handleSkip}
            disabled={completeProfileMutation.isPending}
          >
            {t('onboarding.skipForNow')}
          </Button>
        </Box>
      </Box>
    </AuthLayout>
  );
};

export default CompleteProfilePage;
