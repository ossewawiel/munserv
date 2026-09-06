import { type FC } from 'react';
import { useParams, Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { useAuth } from '@/shared/hooks/useAuth';
import { useWardDashboard } from './hooks';
import { WardWidgets } from './components/WardWidgets';

/**
 * Ward-specific dashboard page for Pod Chief.
 * Shows the same dashboard widgets filtered by ward.
 * Route: /dashboard/ward/:wardId
 */
export const WardDashboardPage: FC = () => {
  const { wardId } = useParams<{ wardId: string }>();
  const { t } = useTranslation();
  const { hasPermission } = useAuth();
  const canViewWardDashboard = hasPermission('pod_chief');
  const { data: stats, isLoading, error, refetch } = useWardDashboard(wardId ?? '', {
    enabled: canViewWardDashboard,
  });

  // Redirect if no wardId provided
  if (!wardId) {
    return <Navigate to="/" replace />;
  }

  const wardName = stats?.wardName ?? t('common.loading');

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={wardName}
        items={[
          { label: t('nav.dashboard'), path: '/', icon: 'home' },
          { label: t('nav.wardDashboards') },
          { label: wardName },
        ]}
      />

      <Box sx={{ mt: 3 }}>
        {!canViewWardDashboard && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.forbidden')}
          />
        )}

        {canViewWardDashboard && error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {canViewWardDashboard && !error && <WardWidgets stats={stats} isLoading={isLoading} />}
      </Box>
    </DashboardLayout>
  );
};

export default WardDashboardPage;
