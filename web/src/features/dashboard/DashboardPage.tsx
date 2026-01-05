import { type FC } from 'react';
import { useTranslation } from 'react-i18next';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { PageHeader } from '@/components/molecules/PageHeader';
import { ErrorState } from '@/components/molecules/ErrorState';
import { CardSkeleton } from '@/components/molecules/LoadingSkeleton';
import { useDashboardStats } from './hooks';
import { StatsGrid } from './components/StatsGrid';
import { IssuesByStateChart } from './components/IssuesByStateChart';
import { IssuesByTypeChart } from './components/IssuesByTypeChart';

export const DashboardPage: FC = () => {
  const { t } = useTranslation();
  const { data, isLoading, error, refetch } = useDashboardStats();

  return (
    <DashboardLayout>
      <PageHeader title={t('dashboard.title')} />

      <div className="mt-6 space-y-6">
        {isLoading && (
          <>
            <CardSkeleton count={4} />
            <div className="grid gap-6 lg:grid-cols-2">
              <div className="h-80 animate-pulse rounded-lg bg-secondary-200" />
              <div className="h-80 animate-pulse rounded-lg bg-secondary-200" />
            </div>
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
            <div className="grid gap-6 lg:grid-cols-2">
              <IssuesByStateChart byState={data.stats.byState} />
              <IssuesByTypeChart byType={data.stats.byType} />
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  );
};

export default DashboardPage;
