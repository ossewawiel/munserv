import { type FC, useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { RegisterForm, type RegisterFormData } from '@/components/molecules/RegisterForm';
import { useRegisterMember, useSectors } from './hooks';

export const RegisterPage: FC = () => {
  const { t } = useTranslation();
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const registerMutation = useRegisterMember();
  const { data: sectors, isLoading: sectorsLoading } = useSectors();

  const handleSubmit = useCallback(
    (data: RegisterFormData) => {
      registerMutation.mutate(data, {
        onSuccess: () => {
          setSuccessMessage(t('auth.registrationSuccess'));
        },
      });
    },
    [registerMutation, t]
  );

  // Show success state
  if (successMessage) {
    return (
      <AuthLayout
        header={t('auth.registrationSuccess')}
        subtitle={t('auth.registrationPendingInfo')}
      >
        <Box sx={{ textAlign: 'center', py: 2 }}>
          <Alert severity="success">
            {t('auth.registrationSuccessMessage')}
          </Alert>
        </Box>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout
      header={t('auth.registerTitle')}
      subtitle={t('auth.registerSubtitle')}
    >
      <RegisterForm
        sectors={sectors ?? []}
        onSubmit={handleSubmit}
        isLoading={registerMutation.isPending || sectorsLoading}
        error={registerMutation.error?.message}
      />
    </AuthLayout>
  );
};

export default RegisterPage;
