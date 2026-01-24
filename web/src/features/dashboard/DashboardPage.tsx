import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import Skeleton from '@mui/material/Skeleton';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { ErrorState } from '@/components/molecules/ErrorState';
import { CardSkeleton } from '@/components/molecules/LoadingSkeleton';
import { SetupBanners, PodChiefWidgets } from '@/features/pod-chief/components';
import { usePodDashboard } from '@/features/pod-chief/hooks';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
import { useDashboardStats } from './hooks';
import { StatsGrid } from './components/StatsGrid';
import { IssuesByStateChart } from './components/IssuesByStateChart';
import { IssuesByTypeChart } from './components/IssuesByTypeChart';

export const DashboardPage: FC = () => {
  const { t } = useTranslation();
  const podSetup = usePodSetup();

  // Fetch sector-level stats for non-pod-level users
  const sectorDashboard = useDashboardStats();

  // Fetch pod-level stats for Pod Chiefs when setup is complete
  const podDashboard = usePodDashboard();

  // Determine which dashboard to show
  const showPodDashboard = podSetup.isPodLevel && podSetup.isSetupComplete;

  // Show setup banners for pod-level users when setup is incomplete
  const showSetupBanners =
    podSetup.isPodLevel &&
    !podSetup.isSetupComplete &&
    podSetup.status?.missingSteps &&
    podSetup.status.missingSteps.length > 0;

  // Select the appropriate data based on user role
  // Pod-level users with incomplete setup don't need to load any dashboard
  const showSectorDashboard = !podSetup.isPodLevel;
  const isLoading = showPodDashboard
    ? podDashboard.isLoading
    : showSectorDashboard
      ? sectorDashboard.isLoading
      : false;
  const error = showPodDashboard
    ? podDashboard.error
    : showSectorDashboard
      ? sectorDashboard.error
      : null;
  const refetch = showPodDashboard ? podDashboard.refetch : sectorDashboard.refetch;

  return (
    <DashboardLayout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
        {/* Setup task banners for Pod Chiefs (W11) */}
        {showSetupBanners && (
          <SetupBanners missingSteps={podSetup.status!.missingSteps} />
        )}

        {isLoading && (
          <>
            <CardSkeleton count={4} />
            <Grid container spacing={3}>
              <Grid size={{ xs: 12, lg: 6 }}>
                <Skeleton variant="rounded" height={320} />
              </Grid>
              <Grid size={{ xs: 12, lg: 6 }}>
                <Skeleton variant="rounded" height={320} />
              </Grid>
            </Grid>
          </>
        )}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {/* Pod Chief dashboard widgets (W12) */}
        {showPodDashboard && podDashboard.data && (
          <PodChiefWidgets stats={podDashboard.data} />
        )}

        {/* Sector-level dashboard for non-pod-level users only */}
        {!podSetup.isPodLevel && sectorDashboard.data && (
          <>
            <StatsGrid stats={sectorDashboard.data.stats} />
            <Grid container spacing={3}>
              <Grid size={{ xs: 12, lg: 6 }}>
                <IssuesByStateChart byState={sectorDashboard.data.stats.byState} />
              </Grid>
              <Grid size={{ xs: 12, lg: 6 }}>
                <IssuesByTypeChart byType={sectorDashboard.data.stats.byType} />
              </Grid>
            </Grid>
          </>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default DashboardPage;
