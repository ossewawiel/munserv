import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { SupportAccessSection } from '@/features/support-access/SupportAccessSection';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
import { PodIdentitySection } from './components/PodIdentitySection';
import { BoundaryPlaceholderCard } from './components/BoundaryPlaceholderCard';

/**
 * Pod Settings page for Pod Chiefs: pod-wide configuration, including
 * granting the super user temporary support access.
 */
export const PodSettingsPage: FC = () => {
  const { t } = useTranslation();
  const { status } = usePodSetup();
  const hasWards = Boolean(status && status.wards.length > 0);
  const areaCopy = hasWards
    ? {
        titleKey: 'podSettings.boundaries.ward.title',
        titleFallback: 'Ward boundaries',
        descriptionKey: 'podSettings.boundaries.ward.description',
        descriptionFallback:
          "Draw each ward's outline so a ward chief sees exactly the ground they are responsible for.",
      }
    : {
        titleKey: 'podSettings.boundaries.sector.title',
        titleFallback: 'Sector boundaries',
        descriptionKey: 'podSettings.boundaries.sector.description',
        descriptionFallback:
          "Draw each sector's outline so an issue reaches the right sector from the GPS point it was reported at.",
      };

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
        <Stack spacing={3}>
          <PodIdentitySection />
          <Box sx={{ display: 'flex', gap: 3, alignItems: 'stretch' }}>
            <BoundaryPlaceholderCard
              title={t('podSettings.boundaries.pod.title', 'Pod boundaries')}
              description={t(
                'podSettings.boundaries.pod.description',
                'Draw the outline of the whole pod. Reports from outside it are refused, and every map opens on it.'
              )}
            />
            <BoundaryPlaceholderCard
              title={t(areaCopy.titleKey, areaCopy.titleFallback)}
              description={t(areaCopy.descriptionKey, areaCopy.descriptionFallback)}
            />
          </Box>
          <SupportAccessSection />
        </Stack>
      </Box>
    </DashboardLayout>
  );
};
