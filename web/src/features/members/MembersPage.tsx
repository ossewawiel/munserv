import { type FC, useCallback, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import AssignmentIcon from '@mui/icons-material/Assignment';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { EmptyState } from '@/components/molecules/EmptyState';
import { MemberStatusBadge } from '@/components/molecules/MemberStatusBadge';
import {
  DataTableCard,
  type DataTableTab,
} from '@/components/organisms/DataTableCard';
import type { Column } from '@/components/organisms/DataTable';
import type { MemberStatus } from '@/features/auth/types';
import {
  useMembers,
  useApproveMember,
  useRejectMember,
  usePendingMemberCount,
} from './hooks';
import { MemberApprovalDialog } from './components/MemberApprovalDialog';
import { MemberNameCell } from './components/MemberNameCell';
import { MemberActionButtons } from './components/MemberActionButtons';
import type { MemberListItem } from './types';

const DEFAULT_PAGE_SIZE = 10;
const PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

type StatusFilter = 'all' | MemberStatus;

export const MembersPage: FC = () => {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();

  // URL state
  const statusFilter = (searchParams.get('status') as StatusFilter) || 'all';
  const currentPage = Number(searchParams.get('page')) || 1;
  const pageSize =
    Number(searchParams.get('pageSize')) || DEFAULT_PAGE_SIZE;

  // Dialog state
  const [approvalDialog, setApprovalDialog] = useState<{
    open: boolean;
    action: 'approve' | 'reject';
    member: MemberListItem | null;
  }>({ open: false, action: 'approve', member: null });

  // Data fetching
  const { data, isLoading, error, refetch } = useMembers({
    page: currentPage,
    limit: pageSize,
    status: statusFilter === 'all' ? undefined : statusFilter,
  });

  // Get pending count for badge
  const { data: pendingCount } = usePendingMemberCount();

  // Mutations
  const approveMutation = useApproveMember();
  const rejectMutation = useRejectMember();

  // Tab change handler
  const handleTabChange = useCallback(
    (newValue: StatusFilter) => {
      setSearchParams((prev) => {
        prev.set('page', '1');
        if (newValue === 'all') {
          prev.delete('status');
        } else {
          prev.set('status', newValue);
        }
        return prev;
      });
    },
    [setSearchParams]
  );

  // Pagination handlers
  const handlePageChange = useCallback(
    (page: number) => {
      setSearchParams((prev) => {
        prev.set('page', String(page));
        return prev;
      });
    },
    [setSearchParams]
  );

  const handlePageSizeChange = useCallback(
    (newPageSize: number) => {
      setSearchParams((prev) => {
        prev.set('pageSize', String(newPageSize));
        prev.set('page', '1');
        return prev;
      });
    },
    [setSearchParams]
  );

  // Approval handlers
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

  // Date formatter
  const formatDate = useCallback((dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }, []);

  // Tab configuration
  const tabs = useMemo<DataTableTab<StatusFilter>[]>(
    () => [
      {
        value: 'all',
        label: t('members.filterAll'),
      },
      {
        value: 'pending_approval',
        label: t('members.filterPending'),
        badge: pendingCount,
        badgeColor: 'warning',
      },
      {
        value: 'active',
        label: t('members.filterActive'),
      },
      {
        value: 'suspended',
        label: t('members.filterSuspended'),
      },
    ],
    [t, pendingCount]
  );

  // Column configuration
  const columns = useMemo<Column<MemberListItem>[]>(
    () => [
      {
        key: 'name',
        header: t('members.name'),
        render: (member) => <MemberNameCell member={member} />,
      },
      {
        key: 'phone',
        header: t('members.phone'),
        width: '140px',
        render: (member) => (
          <Typography variant="body2" color="text.secondary">
            {member.phoneNumber}
          </Typography>
        ),
      },
      {
        key: 'address',
        header: t('members.address'),
        render: (member) => (
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{
              maxWidth: 200,
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
            title={member.address}
          >
            {member.address}
          </Typography>
        ),
      },
      {
        key: 'status',
        header: t('members.status'),
        width: '140px',
        render: (member) => <MemberStatusBadge status={member.status} />,
      },
      {
        key: 'issuesReported',
        header: t('members.issuesReported'),
        width: '100px',
        align: 'center',
        render: (member) => (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 0.5,
              color: 'text.secondary',
            }}
          >
            <AssignmentIcon sx={{ fontSize: 16 }} />
            <Typography variant="body2">{member.issueCount}</Typography>
          </Box>
        ),
      },
      {
        key: 'joinedAt',
        header: t('members.joinedAt'),
        width: '130px',
        render: (member) => (
          <Typography variant="body2" color="text.secondary">
            {formatDate(member.joinedAt)}
          </Typography>
        ),
      },
      // Actions column - only show when filtering shows pending members
      ...(statusFilter === 'pending_approval' || statusFilter === 'all'
        ? [
            {
              key: 'actions',
              header: t('members.actions'),
              width: '120px',
              align: 'center' as const,
              render: (member: MemberListItem) =>
                member.status === 'pending_approval' ? (
                  <MemberActionButtons
                    onApprove={() => handleApproveClick(member)}
                    onReject={() => handleRejectClick(member)}
                  />
                ) : null,
            },
          ]
        : []),
    ],
    [t, formatDate, statusFilter, handleApproveClick, handleRejectClick]
  );

  if (error) {
    return (
      <DashboardLayout>
        <Breadcrumbs
          title={t('members.title')}
          items={[
            { label: t('dashboard.title'), path: '/', icon: 'home' },
            { label: t('members.title') },
          ]}
        />
        <Box sx={{ mt: 3 }}>
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('members.title')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('members.title') },
        ]}
      />

      <Box sx={{ mt: 3 }}>
        <DataTableCard
          columns={columns}
          data={data?.items ?? []}
          keyExtractor={(member) => member.id}
          totalItems={data?.pagination.totalItems ?? 0}
          currentPage={data?.pagination.page ?? currentPage}
          pageSize={data?.pagination.limit ?? pageSize}
          pageSizeOptions={PAGE_SIZE_OPTIONS}
          onPageChange={handlePageChange}
          onPageSizeChange={handlePageSizeChange}
          isLoading={isLoading}
          hideToolbarWhenEmpty
          tabs={{
            tabs,
            value: statusFilter,
            onChange: handleTabChange,
            ariaLabel: t('members.filterByStatus'),
          }}
          emptyMessage={
            <EmptyState
              title={t('members.noMembers')}
              description={
                statusFilter === 'pending_approval'
                  ? t('members.noPendingMembers')
                  : t('members.noMembersDescription')
              }
            />
          }
        />
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
