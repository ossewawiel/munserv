import { type FC, useCallback } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { TableSkeleton } from '@/components/molecules/LoadingSkeleton';
import { Pagination } from '@/components/molecules/Pagination';
import { useIssues } from './hooks';
import { IssueFilters } from './components/IssueFilters';
import { IssuesTable } from './components/IssuesTable';
import type { IssueState, IssueType, IssueSummary } from './types';

const PAGE_SIZE = 10;

export const IssuesPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const state = (searchParams.get('state') as IssueState) || undefined;
  const type = (searchParams.get('type') as IssueType) || undefined;
  const page = Number.parseInt(searchParams.get('page') || '1', 10);

  const { data, isLoading, error, refetch } = useIssues({
    state,
    type,
    page,
    limit: PAGE_SIZE,
  });

  const handleStateChange = useCallback(
    (newState: IssueState | undefined) => {
      setSearchParams((prev) => {
        if (newState) {
          prev.set('state', newState);
        } else {
          prev.delete('state');
        }
        prev.set('page', '1');
        return prev;
      });
    },
    [setSearchParams]
  );

  const handleTypeChange = useCallback(
    (newType: IssueType | undefined) => {
      setSearchParams((prev) => {
        if (newType) {
          prev.set('type', newType);
        } else {
          prev.delete('type');
        }
        prev.set('page', '1');
        return prev;
      });
    },
    [setSearchParams]
  );

  const handleClearFilters = useCallback(() => {
    setSearchParams({});
  }, [setSearchParams]);

  const handlePageChange = useCallback(
    (newPage: number) => {
      setSearchParams((prev) => {
        prev.set('page', String(newPage));
        return prev;
      });
    },
    [setSearchParams]
  );

  const handleRowClick = useCallback(
    (issue: IssueSummary) => {
      navigate(`/issues/${issue.id}`);
    },
    [navigate]
  );

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('issues.title')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('issues.title') },
        ]}
      />

      <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 3 }}>
        <IssueFilters
          state={state}
          type={type}
          onStateChange={handleStateChange}
          onTypeChange={handleTypeChange}
          onClear={handleClearFilters}
        />

        {isLoading && <TableSkeleton rows={5} columns={5} />}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {data && (
          <>
            <IssuesTable issues={data.items} onRowClick={handleRowClick} />
            <Pagination
              currentPage={data.pagination.page}
              totalPages={data.pagination.totalPages}
              totalItems={data.pagination.totalItems}
              pageSize={data.pagination.limit}
              onPageChange={handlePageChange}
            />
          </>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default IssuesPage;
