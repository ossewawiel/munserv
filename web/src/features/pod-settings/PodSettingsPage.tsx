import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { SupportAccessSection } from '@/features/support-access/SupportAccessSection';

/**
 * Pod Settings page for Pod Chiefs: pod-wide configuration, including
 * granting the super user temporary support access.
 */
export const PodSettingsPage: FC = () => {
  const { t } = useTranslation();

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('podSettings.title', 'Pod Settings')}
        subtitle={t(
          'podSettings.subtitle',
          'Pod-wide configuration, including support access for Central Authority.'
        )}
        items={[
          { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
          { label: t('podSettings.title', 'Pod Settings') },
        ]}
      />

      <Box sx={{ mt: 3 }}>
        <SupportAccessSection />
      </Box>
    </DashboardLayout>
  );
};
