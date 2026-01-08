import { type FC, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { PageHeader } from '@/components/molecules/PageHeader';
import { ErrorState } from '@/components/molecules/ErrorState';
import { LoadingSkeleton } from '@/components/molecules/LoadingSkeleton';
import { EmptyState } from '@/components/molecules/EmptyState';
import { useHeatReport } from './hooks';
import { HeatReportTable } from './components/HeatReportTable';
import type { HeatReportItem } from './types';

export const HeatReportPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { data: report, isLoading, error, refetch } = useHeatReport();

  const handleRowClick = useCallback(
    (item: HeatReportItem) => {
      navigate(`/issues/${item.id}`);
    },
    [navigate]
  );

  const formatGeneratedAt = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleString();
  };

  return (
    <DashboardLayout>
      <PageHeader
        title={t('heatReport.title')}
        subtitle={
          report
            ? `${t('heatReport.generatedAt')}: ${formatGeneratedAt(report.generatedAt)}`
            : undefined
        }
      />

      <Box sx={{ mt: 3 }}>
        {isLoading && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <LoadingSkeleton variant="rect" height={400} />
          </Box>
        )}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {report?.items.length === 0 && (
          <EmptyState
            title={t('common.noResults')}
            description={t('issues.noIssuesDescription')}
          />
        )}

        {report && report.items.length > 0 && (
          <HeatReportTable items={report.items} onRowClick={handleRowClick} />
        )}
      </Box>
    </DashboardLayout>
  );
};

export default HeatReportPage;
