import { type FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import { AuthLayout } from '@/components/templates/AuthLayout';

/**
 * Placeholder for Create Pod Chief page.
 * Full implementation in W23.
 */
export const CreatePodChiefPage: FC = () => {
  const { t } = useTranslation();

  // Check if user is super user
  const isSuperUser = localStorage.getItem('isSuperUser') === 'true';

  if (!isSuperUser) {
    return <Navigate to="/login" replace />;
  }

  return (
    <AuthLayout
      header={t('bootstrap.createPodChief')}
      subtitle={t('bootstrap.createPodChiefDescription')}
    >
      <Box sx={{ textAlign: 'center', py: 4 }}>
        <Typography variant="body1" color="text.secondary">
          {t('bootstrap.comingSoon')}
        </Typography>
      </Box>
    </AuthLayout>
  );
};

export default CreatePodChiefPage;
