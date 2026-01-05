import { type FC, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { PageHeader } from '@/components/molecules/PageHeader';
import { ErrorState } from '@/components/molecules/ErrorState';
import { LoadingSkeleton } from '@/components/molecules/LoadingSkeleton';
import { EmptyState } from '@/components/molecules/EmptyState';
import { Pagination } from '@/components/molecules/Pagination';
import { useMembers } from './hooks';
import { MembersTable } from './components/MembersTable';

const PAGE_SIZE = 10;

export const MembersPage: FC = () => {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();

  const currentPage = Number(searchParams.get('page')) || 1;

  const { data, isLoading, error, refetch } = useMembers({
    page: currentPage,
    limit: PAGE_SIZE,
  });

  const handlePageChange = useCallback(
    (page: number) => {
      const params = new URLSearchParams(searchParams);
      params.set('page', String(page));
      setSearchParams(params);
    },
    [searchParams, setSearchParams]
  );

  return (
    <DashboardLayout>
      <PageHeader title={t('members.title')} />

      <div className="mt-6 space-y-4">
        {isLoading && (
          <div className="space-y-4">
            <LoadingSkeleton variant="rect" height={400} />
          </div>
        )}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {data && data.items.length === 0 && (
          <EmptyState
            title={t('common.noResults')}
            description={t('common.noResults')}
          />
        )}

        {data && data.items.length > 0 && (
          <>
            <MembersTable members={data.items} />
            <Pagination
              currentPage={data.pagination.page}
              totalPages={data.pagination.totalPages}
              totalItems={data.pagination.totalItems}
              pageSize={data.pagination.limit}
              onPageChange={handlePageChange}
            />
          </>
        )}
      </div>
    </DashboardLayout>
  );
};

export default MembersPage;
