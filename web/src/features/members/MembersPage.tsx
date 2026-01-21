import { type FC, useCallback, useMemo, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
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
  useGARequestsCount,
} from './hooks';
import {
  useInviteGroundAdmin,
  useRevokeGroundAdminInvite,
} from '@/features/ground-admins/hooks';
import { MemberApprovalDialog } from './components/MemberApprovalDialog';
import { MemberNameCell } from './components/MemberNameCell';
import { MemberActionsCell } from './components/MemberActionsCell';
import { InviteDialog } from '@/features/ground-admins/components/InviteDialog';
import { RevokeInviteDialog } from '@/features/ground-admins/components/RevokeInviteDialog';
import type { MemberListItem, MemberFilterParams } from './types';

const DEFAULT_PAGE_SIZE = 10;
const PAGE_SIZE_OPTIONS = [5, 10, 20] as const;

// Extended filter type to include Ground Admin filters
type StatusFilter =
  | 'all'
  | MemberStatus
  | 'ground_admins'
  | 'ga_requests'
  | 'pending_ga_invites';

/**
 * Maps tab filter value to API params
 */
function getFilterParams(filter: StatusFilter): Partial<MemberFilterParams> {
  switch (filter) {
    case 'all':
      return {};
    case 'ground_admins':
      return { isGroundAdmin: true };
    case 'ga_requests':
      return { hasPendingApplication: true };
    case 'pending_ga_invites':
      return { hasInvitationPending: true };
    default:
      // MemberStatus values
      return { status: filter as MemberStatus };
  }
}

export const MembersPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  // URL state
  const statusFilter = (searchParams.get('status') as StatusFilter) || 'all';
  const currentPage = Number(searchParams.get('page')) || 1;
  const pageSize = Number(searchParams.get('pageSize')) || DEFAULT_PAGE_SIZE;

  // Dialog state
  const [approvalDialog, setApprovalDialog] = useState<{
    open: boolean;
    action: 'approve' | 'reject';
    member: MemberListItem | null;
  }>({ open: false, action: 'approve', member: null });

  // Ground Admin invite dialog state
  const [inviteDialog, setInviteDialog] = useState<{
    open: boolean;
    member: MemberListItem | null;
  }>({ open: false, member: null });

  // Revoke invite dialog state
  const [revokeDialog, setRevokeDialog] = useState<{
    open: boolean;
    member: MemberListItem | null;
  }>({ open: false, member: null });

  // Data fetching with filter params
  const filterParams = getFilterParams(statusFilter);
  const { data, isLoading, error, refetch } = useMembers({
    page: currentPage,
    limit: pageSize,
    ...filterParams,
  });

  // Badge counts
  const { data: pendingCount } = usePendingMemberCount();
  const { data: gaRequestsCount } = useGARequestsCount();

  // Mutations
  const approveMutation = useApproveMember();
  const rejectMutation = useRejectMember();
  const inviteMutation = useInviteGroundAdmin();
  const revokeInviteMutation = useRevokeGroundAdminInvite();

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
  const handleApproveClick = useCallback(
    (member: MemberListItem) => {
      setApprovalDialog({ open: true, action: 'approve', member });
    },
    [setApprovalDialog]
  );

  const handleRejectClick = useCallback(
    (member: MemberListItem) => {
      setApprovalDialog({ open: true, action: 'reject', member });
    },
    [setApprovalDialog]
  );

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
  }, [approvalDialog, approveMutation, rejectMutation, refetch, setApprovalDialog]);

  const handleApprovalCancel = useCallback(() => {
    setApprovalDialog({ open: false, action: 'approve', member: null });
  }, [setApprovalDialog]);

  // Ground Admin invite handlers
  const handleInviteClick = useCallback(
    (member: MemberListItem) => {
      setInviteDialog({ open: true, member });
    },
    [setInviteDialog]
  );

  const handleInviteConfirm = useCallback(
    (message?: string) => {
      if (!inviteDialog.member) return;

      inviteMutation.mutate(
        { memberId: inviteDialog.member.id, message },
        {
          onSuccess: () => {
            setInviteDialog({ open: false, member: null });
            refetch();
          },
          onError: (error) => {
            // Log error for debugging - in production this would show a toast/snackbar
            console.error('Failed to send Ground Admin invitation:', error);
            // Still close the dialog on error to avoid stuck state
            setInviteDialog({ open: false, member: null });
          },
        }
      );
    },
    [inviteDialog.member, inviteMutation, refetch, setInviteDialog]
  );

  const handleInviteCancel = useCallback(() => {
    setInviteDialog({ open: false, member: null });
  }, [setInviteDialog]);

  // Revoke invite handlers
  const handleRevokeInviteClick = useCallback(
    (member: MemberListItem) => {
      setRevokeDialog({ open: true, member });
    },
    [setRevokeDialog]
  );

  const handleRevokeInviteConfirm = useCallback(() => {
    if (!revokeDialog.member || !revokeDialog.member.pendingApplicationId)
      return;

    revokeInviteMutation.mutate(
      {
        memberId: revokeDialog.member.id,
        applicationId: revokeDialog.member.pendingApplicationId,
      },
      {
        onSuccess: () => {
          setRevokeDialog({ open: false, member: null });
          refetch();
        },
      }
    );
  }, [revokeDialog.member, revokeInviteMutation, refetch, setRevokeDialog]);

  const handleRevokeInviteCancel = useCallback(() => {
    setRevokeDialog({ open: false, member: null });
  }, [setRevokeDialog]);

  // Review application handler - navigate to messages
  const handleReviewApplication = useCallback(() => {
    navigate('/messages');
  }, [navigate]);

  // Manage Ground Admin handler - navigate to Ground Admins page
  const handleManageGroundAdmin = useCallback(() => {
    navigate('/ground-admins');
  }, [navigate]);

  // Date formatter
  const formatDate = useCallback((dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }, []);

  // Tab configuration - 7 tabs total
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
      {
        value: 'ground_admins',
        label: t('members.filterGroundAdmins'),
      },
      {
        value: 'ga_requests',
        label: t('members.filterGARequests'),
        badge: gaRequestsCount,
        badgeColor: 'info',
      },
      {
        value: 'pending_ga_invites',
        label: t('members.filterPendingInvites'),
      },
    ],
    [t, pendingCount, gaRequestsCount]
  );

  // Column configuration - SAME for all tabs (no conditional columns)
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
      {
        key: 'actions',
        header: t('members.actions'),
        width: '120px',
        align: 'center',
        render: (member) => (
          <MemberActionsCell
            member={member}
            onApprove={handleApproveClick}
            onReject={handleRejectClick}
            onInvite={handleInviteClick}
            onReviewApplication={handleReviewApplication}
            onManage={handleManageGroundAdmin}
            onRevokeInvite={handleRevokeInviteClick}
          />
        ),
      },
    ],
    [
      t,
      formatDate,
      handleApproveClick,
      handleRejectClick,
      handleInviteClick,
      handleReviewApplication,
      handleManageGroundAdmin,
      handleRevokeInviteClick,
    ]
  );

  // Get empty message based on current filter
  const getEmptyMessage = useCallback(() => {
    switch (statusFilter) {
      case 'pending_approval':
        return t('members.noPendingMembers');
      case 'ground_admins':
        return t('members.noGroundAdmins');
      case 'ga_requests':
        return t('members.noGARequests');
      case 'pending_ga_invites':
        return t('members.noPendingInvites');
      default:
        return t('members.noMembersDescription');
    }
  }, [statusFilter, t]);

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
              description={getEmptyMessage()}
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

      {/* Ground Admin Invite Dialog */}
      <InviteDialog
        open={inviteDialog.open}
        member={
          inviteDialog.member
            ? {
                id: inviteDialog.member.id,
                name: `${inviteDialog.member.firstName} ${inviteDialog.member.surname}`,
              }
            : null
        }
        onClose={handleInviteCancel}
        onConfirm={handleInviteConfirm}
        isLoading={inviteMutation.isPending}
      />

      {/* Revoke Invite Dialog */}
      <RevokeInviteDialog
        open={revokeDialog.open}
        member={
          revokeDialog.member
            ? {
                id: revokeDialog.member.id,
                name: `${revokeDialog.member.firstName} ${revokeDialog.member.surname}`,
              }
            : null
        }
        onClose={handleRevokeInviteCancel}
        onConfirm={handleRevokeInviteConfirm}
        isLoading={revokeInviteMutation.isPending}
      />
    </DashboardLayout>
  );
};

export default MembersPage;
