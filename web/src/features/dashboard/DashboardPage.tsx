import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import Skeleton from '@mui/material/Skeleton';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { ErrorState } from '@/components/molecules/ErrorState';
import { CardSkeleton } from '@/components/molecules/LoadingSkeleton';
import { SetupBanners } from '@/features/pod-chief/components';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
import { useDashboardStats } from './hooks';
import { StatsGrid } from './components/StatsGrid';
import { IssuesByStateChart } from './components/IssuesByStateChart';
import { IssuesByTypeChart } from './components/IssuesByTypeChart';

export const DashboardPage: FC = () => {
  const { t } = useTranslation();
  const { data, isLoading, error, refetch } = useDashboardStats();
  const podSetup = usePodSetup();

  // Show setup banners for pod-level users when setup is incomplete
  const showSetupBanners =
    podSetup.isPodLevel &&
    !podSetup.isSetupComplete &&
    podSetup.status?.missingSteps &&
    podSetup.status.missingSteps.length > 0;

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

        {data && (
          <>
            <StatsGrid stats={data.stats} />
            <Grid container spacing={3}>
              <Grid size={{ xs: 12, lg: 6 }}>
                <IssuesByStateChart byState={data.stats.byState} />
              </Grid>
              <Grid size={{ xs: 12, lg: 6 }}>
                <IssuesByTypeChart byType={data.stats.byType} />
              </Grid>
            </Grid>
          </>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default DashboardPage;
