import { type FC, useCallback, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Badge from '@mui/material/Badge';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { LoadingSkeleton } from '@/components/molecules/LoadingSkeleton';
import { EmptyState } from '@/components/molecules/EmptyState';
import { Pagination } from '@/components/molecules/Pagination';
import type { MemberStatus } from '@/features/auth/types';
import {
  useMembers,
  useApproveMember,
  useRejectMember,
  usePendingMemberCount,
} from './hooks';
import { MembersTable } from './components/MembersTable';
import { MemberApprovalDialog } from './components/MemberApprovalDialog';
import type { MemberListItem } from './types';

const PAGE_SIZE = 10;

type StatusFilter = 'all' | MemberStatus;

export const MembersPage: FC = () => {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();

  // State
  const [statusFilter, setStatusFilter] = useState<StatusFilter>(
    (searchParams.get('status') as StatusFilter) || 'all'
  );
  const [approvalDialog, setApprovalDialog] = useState<{
    open: boolean;
    action: 'approve' | 'reject';
    member: MemberListItem | null;
  }>({ open: false, action: 'approve', member: null });

  // Pagination
  const currentPage = Number(searchParams.get('page')) || 1;

  // Data fetching
  const { data, isLoading, error, refetch } = useMembers({
    page: currentPage,
    limit: PAGE_SIZE,
    status: statusFilter === 'all' ? undefined : statusFilter,
  });

  // Get pending count for badge
  const { data: pendingCount } = usePendingMemberCount();

  // Mutations
  const approveMutation = useApproveMember();
  const rejectMutation = useRejectMember();

  // Handlers
  const handlePageChange = useCallback(
    (page: number) => {
      const params = new URLSearchParams(searchParams);
      params.set('page', String(page));
      setSearchParams(params);
    },
    [searchParams, setSearchParams]
  );

  const handleStatusFilterChange = useCallback(
    (_: React.SyntheticEvent, newValue: StatusFilter) => {
      setStatusFilter(newValue);
      const params = new URLSearchParams(searchParams);
      params.set('page', '1');
      if (newValue === 'all') {
        params.delete('status');
      } else {
        params.set('status', newValue);
      }
      setSearchParams(params);
    },
    [searchParams, setSearchParams]
  );

  const handleApproveClick = useCallback((member: MemberListItem) => {
    setApprovalDialog({ open: true, action: 'approve', member });
  }, []);

  const handleRejectClick = useCallback((member: MemberListItem) => {
    setApprovalDialog({ open: true, action: 'reject', member });
  }, []);

  const handleApprovalConfirm = useCallback(() => {
    if (!approvalDialog.member) return;

    const mutation =
      approvalDialog.action === 'approve' ? approveMutation : rejectMutation;

    mutation.mutate(approvalDialog.member.id, {
      onSuccess: () => {
        setApprovalDialog({ open: false, action: 'approve', member: null });
        refetch();
      },
    });
  }, [approvalDialog, approveMutation, rejectMutation, refetch]);

  const handleApprovalCancel = useCallback(() => {
    setApprovalDialog({ open: false, action: 'approve', member: null });
  }, []);

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('members.title')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('members.title') },
        ]}
      />

      {/* Status Filter Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mt: 2 }}>
        <Tabs
          value={statusFilter}
          onChange={handleStatusFilterChange}
          aria-label={t('members.filterByStatus')}
        >
          <Tab value="all" label={t('members.filterAll')} />
          <Tab
            value="pending_approval"
            label={
              <Badge
                badgeContent={pendingCount}
                color="warning"
                sx={{ '& .MuiBadge-badge': { right: -10, top: 0 } }}
              >
                {t('members.filterPending')}
              </Badge>
            }
          />
          <Tab value="active" label={t('members.filterActive')} />
          <Tab value="suspended" label={t('members.filterSuspended')} />
        </Tabs>
      </Box>

      <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 2 }}>
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

        {data?.items.length === 0 && (
          <EmptyState
            title={t('members.noMembers')}
            description={
              statusFilter === 'pending_approval'
                ? t('members.noPendingMembers')
                : t('members.noMembersDescription')
            }
          />
        )}

        {data && data.items.length > 0 && (
          <>
            <MembersTable
              members={data.items}
              showApprovalActions={
                statusFilter === 'pending_approval' || statusFilter === 'all'
              }
              onApprove={handleApproveClick}
              onReject={handleRejectClick}
            />
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

      {/* Approval Confirmation Dialog */}
      <MemberApprovalDialog
        open={approvalDialog.open}
        action={approvalDialog.action}
        member={approvalDialog.member}
        isLoading={approveMutation.isPending || rejectMutation.isPending}
        onConfirm={handleApprovalConfirm}
        onCancel={handleApprovalCancel}
      />
    </DashboardLayout>
  );
};

export default MembersPage;
