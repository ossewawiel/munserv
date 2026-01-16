import { type FC, useCallback, useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import MapIcon from '@mui/icons-material/Map';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { EmptyState } from '@/components/molecules/EmptyState';
import { DataTableCard } from '@/components/organisms/DataTableCard';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { HeatBadge } from '@/components/molecules/HeatIndicator';
import { ActionButton } from '@/components/atoms/ActionButton';
import { useIssues } from './hooks';
import { IssueFilters } from './components/IssueFilters';
import type { Column } from '@/components/organisms/DataTable';
import type { IssueState, IssueType, IssueSummary } from './types';

const DEFAULT_PAGE_SIZE = 10;
const PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

export const IssuesPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const state = (searchParams.get('state') as IssueState) || undefined;
  const type = (searchParams.get('type') as IssueType) || undefined;
  const page = Number.parseInt(searchParams.get('page') || '1', 10);
  const pageSize = Number.parseInt(
    searchParams.get('pageSize') || String(DEFAULT_PAGE_SIZE),
    10
  );

  const { data, isLoading, error, refetch } = useIssues({
    state,
    type,
    page,
    limit: pageSize,
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
    setSearchParams((prev) => {
      prev.delete('state');
      prev.delete('type');
      prev.set('page', '1');
      return prev;
    });
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

  const handlePageSizeChange = useCallback(
    (newPageSize: number) => {
      setSearchParams((prev) => {
        prev.set('pageSize', String(newPageSize));
        prev.set('page', '1'); // Reset to first page when changing page size
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

  const columns = useMemo<Column<IssueSummary>[]>(
    () => [
      {
        key: 'thumbnail',
        header: '',
        width: '64px',
        render: (issue) => (
          <Box
            component="img"
            src={issue.thumbnailUrl}
            alt={t(`issues.types.${issue.type}`)}
            sx={{
              width: 48,
              height: 48,
              borderRadius: 1,
              objectFit: 'cover',
            }}
          />
        ),
      },
      {
        key: 'type',
        header: t('issues.type'),
        render: (issue) => <IssueTypeBadge type={issue.type} />,
      },
      {
        key: 'state',
        header: t('issues.state'),
        render: (issue) => <IssueStateBadge state={issue.state} />,
      },
      {
        key: 'heat',
        header: t('issues.heat'),
        align: 'center' as const,
        render: (issue) => <HeatBadge heat={issue.heat} />,
      },
      {
        key: 'createdAt',
        header: t('issues.createdAt'),
        render: (issue) =>
          new Date(issue.createdAt).toLocaleDateString(undefined, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
          }),
      },
    ],
    [t]
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

      <Box sx={{ mt: 3 }}>
        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {!error && (
          <DataTableCard
            columns={columns}
            data={data?.items ?? []}
            keyExtractor={(issue) => issue.id}
            totalItems={data?.pagination.totalItems ?? 0}
            currentPage={data?.pagination.page ?? page}
            pageSize={data?.pagination.limit ?? pageSize}
            pageSizeOptions={PAGE_SIZE_OPTIONS}
            onPageChange={handlePageChange}
            onPageSizeChange={handlePageSizeChange}
            onRowClick={handleRowClick}
            isLoading={isLoading}
            filterSlot={
              <IssueFilters
                state={state}
                type={type}
                onStateChange={handleStateChange}
                onTypeChange={handleTypeChange}
                onClear={handleClearFilters}
              />
            }
            actionSlot={
              <ActionButton
                icon={<MapIcon />}
                onClick={() => navigate('/issues/map')}
              >
                {t('issues.actions.viewMap')}
              </ActionButton>
            }
            emptyMessage={
              <EmptyState
                title={t('common.noResults')}
                description={t('issues.noIssuesDescription')}
              />
            }
          />
        )}
      </Box>
    </DashboardLayout>
  );
};

export default IssuesPage;
