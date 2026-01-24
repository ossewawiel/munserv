import { type FC } from 'react';
import { useParams, Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { useSectorDashboard } from './hooks';
import { SectorWidgets } from './components/SectorWidgets';

/**
 * Sector-specific dashboard page for Pod Chief.
 * Shows the same dashboard widgets filtered by sector.
 * Route: /dashboard/sector/:sectorId
 */
export const SectorDashboardPage: FC = () => {
  const { sectorId } = useParams<{ sectorId: string }>();
  const { t } = useTranslation();
  const { data: stats, isLoading, error, refetch } = useSectorDashboard(sectorId ?? '');

  // Redirect if no sectorId provided
  if (!sectorId) {
    return <Navigate to="/" replace />;
  }

  const sectorName = stats?.sectorName ?? t('common.loading');

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={sectorName}
        items={[
          { label: t('nav.dashboard'), path: '/', icon: 'home' },
          { label: t('nav.sectorDashboards') },
          { label: sectorName },
        ]}
      />

      <Box sx={{ mt: 3 }}>
        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {!error && <SectorWidgets stats={stats} isLoading={isLoading} />}
      </Box>
    </DashboardLayout>
  );
};

export default SectorDashboardPage;
