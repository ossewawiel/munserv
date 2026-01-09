import { type FC, useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';
import MuiButton from '@mui/material/Button';

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
      <AuthLayout>
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Alert severity="success" sx={{ mb: 3 }}>
            {successMessage}
          </Alert>
          <Typography variant="body1" sx={{ mb: 3 }}>
            {t('auth.registrationPendingInfo')}
          </Typography>
          <MuiButton
            component={Link}
            to="/login"
            variant="contained"
            color="primary"
          >
            {t('auth.backToLogin')}
          </MuiButton>
        </Box>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout>
      <Typography variant="h5" component="h1" gutterBottom>
        {t('auth.registerTitle')}
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        {t('auth.registerSubtitle')}
      </Typography>

      <RegisterForm
        sectors={sectors ?? []}
        onSubmit={handleSubmit}
        isLoading={registerMutation.isPending || sectorsLoading}
        error={registerMutation.error?.message}
      />

      <Box sx={{ mt: 3, textAlign: 'center' }}>
        <Typography variant="body2" color="text.secondary">
          {t('auth.alreadyHaveAccount')}
        </Typography>
        <MuiButton component={Link} to="/login" variant="text" size="small">
          {t('auth.loginLink')}
        </MuiButton>
      </Box>
    </AuthLayout>
  );
};

export default RegisterPage;
