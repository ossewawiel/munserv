# Members Table Ground Admin UX Refactor

**Status:** 🟡 Ready for Implementation
**Priority:** High
**Estimated Scope:** 10-12 files modified/created

## Overview

Refactor the Members table to improve the Ground Admin UX:
1. Remove the separate "Ground Admin" column
2. Move all Ground Admin actions to the existing "Actions" column
3. Make tabs act as pure filters (all tabs show identical columns)
4. Add new tabs for Ground Admin filtering
5. Only show "Invite" button for members who have logged issues (issueCount > 0)
6. Add ability to revoke pending Ground Admin invitations

## Prerequisites

Before starting, read:
- `web/CLAUDE.md` - Web coding standards and patterns
- `web/src/features/members/MembersPage.tsx` - Current implementation
- `web/src/features/members/components/GroundAdminCell.tsx` - Component to be removed
- `web/src/features/members/components/MemberActionButtons.tsx` - Reference for button styling

---

## Task 1: Update Types

### File: `web/src/features/members/types.ts`

Add `pendingApplicationId` field to support revoking invitations:

```typescript
export interface MemberListItem {
  id: string;
  firstName: string;
  surname: string;
  email: string;
  phoneNumber: string;
  address: string;
  status: MemberStatus;
  issueCount: number;
  joinedAt: string;
  /** Whether member is currently a Ground Admin */
  isGroundAdmin: boolean;
  /** Ground Admin status (only present if isGroundAdmin is true) */
  groundAdminStatus?: GroundAdminStatus;
  /** Whether member has a pending Ground Admin application */
  hasPendingApplication?: boolean;
  /** Whether member has a pending Ground Admin invitation */
  hasInvitationPending?: boolean;
  /** Application/invitation ID if pending (needed for revoke action) */
  pendingApplicationId?: string;
}
```

### File: `web/src/features/members/types.ts`

Update `MemberFilterParams` to support new filters:

```typescript
export interface MemberFilterParams {
  sectorId?: string;
  search?: string;
  status?: MemberStatus;
  page?: number;
  limit?: number;
  /** Filter to only Ground Admins */
  isGroundAdmin?: boolean;
  /** Filter to members with pending GA applications */
  hasPendingApplication?: boolean;
  /** Filter to members with pending GA invitations */
  hasInvitationPending?: boolean;
}
```

---

## Task 2: Create MemberActionsCell Component

### File: `web/src/features/members/components/MemberActionsCell.tsx` (NEW)

Create a unified actions cell that shows contextual buttons based on member state.

**Action Priority (show first matching):**
1. `status === 'pending_approval'` → Approve + Reject buttons
2. `isGroundAdmin === true` → Manage button
3. `hasInvitationPending === true` → Revoke Invite button
4. `hasPendingApplication === true` → Review button
5. `status === 'active' && issueCount > 0 && !isGroundAdmin && !hasInvitationPending && !hasPendingApplication` → Invite button
6. Otherwise → null (empty cell)

```typescript
import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import RateReviewIcon from '@mui/icons-material/RateReview';
import SettingsIcon from '@mui/icons-material/Settings';
import PersonRemoveIcon from '@mui/icons-material/PersonRemove';

import type { MemberListItem } from '../types';

interface MemberActionsCellProps {
  member: MemberListItem;
  onApprove: (member: MemberListItem) => void;
  onReject: (member: MemberListItem) => void;
  onInvite: (member: MemberListItem) => void;
  onReviewApplication: (member: MemberListItem) => void;
  onManage: (member: MemberListItem) => void;
  onRevokeInvite: (member: MemberListItem) => void;
}

/**
 * Unified actions cell for the Members table.
 * Shows contextual action buttons based on member state.
 */
export const MemberActionsCell: FC<MemberActionsCellProps> = ({
  member,
  onApprove,
  onReject,
  onInvite,
  onReviewApplication,
  onManage,
  onRevokeInvite,
}) => {
  const { t } = useTranslation();

  const stopPropagation = (e: React.MouseEvent) => e.stopPropagation();

  // Priority 1: Pending member approval
  if (member.status === 'pending_approval') {
    return (
      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
        <Tooltip title={t('members.approve')}>
          <IconButton
            color="success"
            size="small"
            aria-label={t('members.approve')}
            onClick={(e) => {
              stopPropagation(e);
              onApprove(member);
            }}
          >
            <CheckCircleIcon />
          </IconButton>
        </Tooltip>
        <Tooltip title={t('members.reject')}>
          <IconButton
            color="error"
            size="small"
            aria-label={t('members.reject')}
            onClick={(e) => {
              stopPropagation(e);
              onReject(member);
            }}
          >
            <CancelIcon />
          </IconButton>
        </Tooltip>
      </Box>
    );
  }

  // Priority 2: Active Ground Admin - show manage
  if (member.isGroundAdmin) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <Tooltip title={t('groundAdmin.manage')}>
          <IconButton
            color="primary"
            size="small"
            aria-label={t('groundAdmin.manage')}
            onClick={(e) => {
              stopPropagation(e);
              onManage(member);
            }}
          >
            <SettingsIcon />
          </IconButton>
        </Tooltip>
      </Box>
    );
  }

  // Priority 3: Pending invitation - show revoke
  if (member.hasInvitationPending) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <Tooltip title={t('members.revokeInvite')}>
          <IconButton
            color="warning"
            size="small"
            aria-label={t('members.revokeInvite')}
            onClick={(e) => {
              stopPropagation(e);
              onRevokeInvite(member);
            }}
          >
            <PersonRemoveIcon />
          </IconButton>
        </Tooltip>
      </Box>
    );
  }

  // Priority 4: Pending application - show review
  if (member.hasPendingApplication) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <Tooltip title={t('groundAdmin.review')}>
          <IconButton
            color="info"
            size="small"
            aria-label={t('groundAdmin.review')}
            onClick={(e) => {
              stopPropagation(e);
              onReviewApplication(member);
            }}
          >
            <RateReviewIcon />
          </IconButton>
        </Tooltip>
      </Box>
    );
  }

  // Priority 5: Active member with issues - show invite
  if (member.status === 'active' && member.issueCount > 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <Tooltip title={t('groundAdmin.invite')}>
          <IconButton
            color="primary"
            size="small"
            aria-label={t('groundAdmin.invite')}
            onClick={(e) => {
              stopPropagation(e);
              onInvite(member);
            }}
          >
            <PersonAddIcon />
          </IconButton>
        </Tooltip>
      </Box>
    );
  }

  // No actions available
  return null;
};
```

---

## Task 3: Add Revoke Invite API Function

### File: `web/src/features/ground-admins/api.ts`

Add the `revokeInvite` function to the existing API:

```typescript
// Add this to the existing groundAdminApi object:

revokeInvite: async (memberId: string, applicationId: string): Promise<{ status: string }> => {
  const response = await apiClient.delete(
    `/v1/members/${memberId}/ground-admin/invite/${applicationId}`
  );
  return response.data;
},
```

---

## Task 4: Add Revoke Invite Hook

### File: `web/src/features/ground-admins/hooks.ts`

Add the mutation hook:

```typescript
// Add this export to the existing hooks file:

export function useRevokeGroundAdminInvite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, applicationId }: { memberId: string; applicationId: string }) =>
      groundAdminApi.revokeInvite(memberId, applicationId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}
```

---

## Task 5: Create RevokeInviteDialog Component

### File: `web/src/features/ground-admins/components/RevokeInviteDialog.tsx` (NEW)

```typescript
import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import CircularProgress from '@mui/material/CircularProgress';

interface RevokeInviteDialogProps {
  open: boolean;
  member: { id: string; name: string } | null;
  onClose: () => void;
  onConfirm: () => void;
  isLoading: boolean;
}

/**
 * Confirmation dialog for revoking a pending Ground Admin invitation.
 */
export const RevokeInviteDialog: FC<RevokeInviteDialogProps> = ({
  open,
  member,
  onClose,
  onConfirm,
  isLoading,
}) => {
  const { t } = useTranslation();

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>{t('members.revokeInvite')}</DialogTitle>
      <DialogContent>
        <DialogContentText>
          {t('members.revokeInviteConfirm', { name: member?.name ?? '' })}
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={isLoading}>
          {t('common.cancel')}
        </Button>
        <Button
          onClick={onConfirm}
          color="warning"
          variant="contained"
          disabled={isLoading}
          startIcon={isLoading ? <CircularProgress size={16} /> : undefined}
        >
          {t('members.revokeInvite')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
```

---

## Task 6: Update Members API

### File: `web/src/features/members/api.ts`

Update the `getAll` function to accept new filter parameters:

```typescript
// Update the params type and API call:

getAll: async (params: MemberFilterParams = {}) => {
  const queryParams: Record<string, string | number | boolean> = {};

  if (params.page) queryParams.page = params.page;
  if (params.limit) queryParams.limit = params.limit;
  if (params.status) queryParams.status = params.status;
  if (params.search) queryParams.search = params.search;
  if (params.isGroundAdmin !== undefined) queryParams.isGroundAdmin = params.isGroundAdmin;
  if (params.hasPendingApplication !== undefined) queryParams.hasPendingApplication = params.hasPendingApplication;
  if (params.hasInvitationPending !== undefined) queryParams.hasInvitationPending = params.hasInvitationPending;

  const response = await apiClient.get<MemberListResponse>('/v1/members', {
    params: queryParams,
  });
  return response.data;
},
```

---

## Task 7: Update useMembers Hook

### File: `web/src/features/members/hooks.ts`

Update the hook to accept and pass the new filter params:

```typescript
export function useMembers(params: MemberFilterParams = {}) {
  return useQuery({
    queryKey: ['members', params],
    queryFn: () => membersApi.getAll(params),
  });
}
```

Add a hook for counting GA requests (for tab badge):

```typescript
export function useGARequestsCount() {
  return useQuery({
    queryKey: ['members', 'gaRequestsCount'],
    queryFn: async () => {
      const response = await membersApi.getAll({
        hasPendingApplication: true,
        limit: 1
      });
      return response.pagination.totalItems;
    },
  });
}
```

---

## Task 8: Refactor MembersPage.tsx

### File: `web/src/features/members/MembersPage.tsx`

This is the main refactor. Key changes:

1. **Update StatusFilter type** to include new filters
2. **Update tabs array** with new tabs
3. **Remove groundAdmin column** from columns array
4. **Update Actions column** to always be visible, use MemberActionsCell
5. **Add revoke invite dialog state and handlers**
6. **Update useMembers call** to map tab values to API params

```typescript
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
import { useInviteGroundAdmin, useRevokeGroundAdminInvite } from '@/features/ground-admins/hooks';
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

  // Ground Admin invite handlers
  const handleInviteClick = useCallback((member: MemberListItem) => {
    setInviteDialog({ open: true, member });
  }, []);

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
        }
      );
    },
    [inviteDialog.member, inviteMutation, refetch]
  );

  const handleInviteCancel = useCallback(() => {
    setInviteDialog({ open: false, member: null });
  }, []);

  // Revoke invite handlers
  const handleRevokeInviteClick = useCallback((member: MemberListItem) => {
    setRevokeDialog({ open: true, member });
  }, []);

  const handleRevokeInviteConfirm = useCallback(() => {
    if (!revokeDialog.member || !revokeDialog.member.pendingApplicationId) return;

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
  }, [revokeDialog.member, revokeInviteMutation, refetch]);

  const handleRevokeInviteCancel = useCallback(() => {
    setRevokeDialog({ open: false, member: null });
  }, []);

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
```

---

## Task 9: Add i18n Keys

### File: `web/src/locales/en/translation.json`

Add these keys to the `members` section:

```json
{
  "members": {
    "filterGroundAdmins": "Ground Admins",
    "filterGARequests": "GA Requests",
    "filterPendingInvites": "Pending Invites",
    "revokeInvite": "Revoke Invitation",
    "revokeInviteConfirm": "Are you sure you want to revoke the Ground Admin invitation for {{name}}?",
    "noGroundAdmins": "No Ground Admins in this sector yet.",
    "noGARequests": "No pending Ground Admin applications.",
    "noPendingInvites": "No pending Ground Admin invitations."
  }
}
```

---

## Task 10: Delete Obsolete Component

### File: `web/src/features/members/components/GroundAdminCell.tsx`

Delete this file - its functionality is now in `MemberActionsCell.tsx`.

Also delete the test file if it exists:
- `web/src/features/members/components/GroundAdminCell.test.tsx`

---

## Task 11: Update/Create Tests

### File: `web/src/features/members/components/MemberActionsCell.test.tsx` (NEW)

Create tests for the new component:

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import { MemberActionsCell } from './MemberActionsCell';
import { TestWrapper } from '@/test/TestWrapper';
import type { MemberListItem } from '../types';

const createMember = (overrides: Partial<MemberListItem> = {}): MemberListItem => ({
  id: '1',
  firstName: 'John',
  surname: 'Doe',
  email: 'john@example.com',
  phoneNumber: '+27123456789',
  address: '123 Main St',
  status: 'active',
  issueCount: 5,
  joinedAt: '2025-01-01T00:00:00Z',
  isGroundAdmin: false,
  ...overrides,
});

const defaultProps = {
  onApprove: vi.fn(),
  onReject: vi.fn(),
  onInvite: vi.fn(),
  onReviewApplication: vi.fn(),
  onManage: vi.fn(),
  onRevokeInvite: vi.fn(),
};

describe('MemberActionsCell', () => {
  it('should show approve/reject for pending_approval members', () => {
    const member = createMember({ status: 'pending_approval' });
    render(
      <MemberActionsCell member={member} {...defaultProps} />,
      { wrapper: TestWrapper }
    );

    expect(screen.getByLabelText(/approve/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/reject/i)).toBeInTheDocument();
  });

  it('should show manage for Ground Admins', () => {
    const member = createMember({ isGroundAdmin: true, groundAdminStatus: 'active' });
    render(
      <MemberActionsCell member={member} {...defaultProps} />,
      { wrapper: TestWrapper }
    );

    expect(screen.getByLabelText(/manage/i)).toBeInTheDocument();
  });

  it('should show revoke for pending invitations', () => {
    const member = createMember({ hasInvitationPending: true, pendingApplicationId: 'app-1' });
    render(
      <MemberActionsCell member={member} {...defaultProps} />,
      { wrapper: TestWrapper }
    );

    expect(screen.getByLabelText(/revoke/i)).toBeInTheDocument();
  });

  it('should show review for pending applications', () => {
    const member = createMember({ hasPendingApplication: true });
    render(
      <MemberActionsCell member={member} {...defaultProps} />,
      { wrapper: TestWrapper }
    );

    expect(screen.getByLabelText(/review/i)).toBeInTheDocument();
  });

  it('should show invite for active members with issues', () => {
    const member = createMember({ status: 'active', issueCount: 5 });
    render(
      <MemberActionsCell member={member} {...defaultProps} />,
      { wrapper: TestWrapper }
    );

    expect(screen.getByLabelText(/invite/i)).toBeInTheDocument();
  });

  it('should show nothing for active members with no issues', () => {
    const member = createMember({ status: 'active', issueCount: 0 });
    const { container } = render(
      <MemberActionsCell member={member} {...defaultProps} />,
      { wrapper: TestWrapper }
    );

    expect(container.firstChild).toBeNull();
  });

  it('should call onInvite when invite clicked', async () => {
    const onInvite = vi.fn();
    const member = createMember({ status: 'active', issueCount: 5 });
    render(
      <MemberActionsCell member={member} {...defaultProps} onInvite={onInvite} />,
      { wrapper: TestWrapper }
    );

    await fireEvent.click(screen.getByLabelText(/invite/i));
    expect(onInvite).toHaveBeenCalledWith(member);
  });
});
```

### File: `web/src/features/ground-admins/components/RevokeInviteDialog.test.tsx` (NEW)

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import { RevokeInviteDialog } from './RevokeInviteDialog';
import { TestWrapper } from '@/test/TestWrapper';

describe('RevokeInviteDialog', () => {
  const defaultProps = {
    open: true,
    member: { id: '1', name: 'John Doe' },
    onClose: vi.fn(),
    onConfirm: vi.fn(),
    isLoading: false,
  };

  it('should render dialog with member name', () => {
    render(<RevokeInviteDialog {...defaultProps} />, { wrapper: TestWrapper });

    expect(screen.getByText(/john doe/i)).toBeInTheDocument();
  });

  it('should call onConfirm when revoke clicked', async () => {
    const onConfirm = vi.fn();
    render(
      <RevokeInviteDialog {...defaultProps} onConfirm={onConfirm} />,
      { wrapper: TestWrapper }
    );

    await fireEvent.click(screen.getByRole('button', { name: /revoke/i }));
    expect(onConfirm).toHaveBeenCalled();
  });

  it('should call onClose when cancel clicked', async () => {
    const onClose = vi.fn();
    render(
      <RevokeInviteDialog {...defaultProps} onClose={onClose} />,
      { wrapper: TestWrapper }
    );

    await fireEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onClose).toHaveBeenCalled();
  });

  it('should disable buttons when loading', () => {
    render(
      <RevokeInviteDialog {...defaultProps} isLoading />,
      { wrapper: TestWrapper }
    );

    expect(screen.getByRole('button', { name: /cancel/i })).toBeDisabled();
    expect(screen.getByRole('button', { name: /revoke/i })).toBeDisabled();
  });
});
```

---

## Task 12: Update MSW Handlers (if needed)

### File: `web/src/test/mocks/handlers.ts`

Add handler for revoke invite endpoint:

```typescript
// Add to existing handlers array:

http.delete('/api/v1/members/:memberId/ground-admin/invite/:applicationId', () => {
  return HttpResponse.json({ status: 'revoked' });
}),

// Update GET /api/v1/members to support new filter params
http.get('/api/v1/members', ({ request }) => {
  const url = new URL(request.url);
  const isGroundAdmin = url.searchParams.get('isGroundAdmin');
  const hasPendingApplication = url.searchParams.get('hasPendingApplication');
  const hasInvitationPending = url.searchParams.get('hasInvitationPending');

  // Filter mock data based on params
  let items = mockMembers;

  if (isGroundAdmin === 'true') {
    items = items.filter(m => m.isGroundAdmin);
  }
  if (hasPendingApplication === 'true') {
    items = items.filter(m => m.hasPendingApplication);
  }
  if (hasInvitationPending === 'true') {
    items = items.filter(m => m.hasInvitationPending);
  }

  return HttpResponse.json({
    items,
    pagination: {
      page: 1,
      limit: 10,
      totalItems: items.length,
      totalPages: 1,
    },
  });
}),
```

---

## File Summary

| Action | File Path |
|--------|-----------|
| MODIFY | `web/src/features/members/types.ts` |
| CREATE | `web/src/features/members/components/MemberActionsCell.tsx` |
| MODIFY | `web/src/features/ground-admins/api.ts` |
| MODIFY | `web/src/features/ground-admins/hooks.ts` |
| CREATE | `web/src/features/ground-admins/components/RevokeInviteDialog.tsx` |
| MODIFY | `web/src/features/members/api.ts` |
| MODIFY | `web/src/features/members/hooks.ts` |
| MODIFY | `web/src/features/members/MembersPage.tsx` |
| MODIFY | `web/src/locales/en/translation.json` |
| DELETE | `web/src/features/members/components/GroundAdminCell.tsx` |
| DELETE | `web/src/features/members/components/GroundAdminCell.test.tsx` (if exists) |
| CREATE | `web/src/features/members/components/MemberActionsCell.test.tsx` |
| CREATE | `web/src/features/ground-admins/components/RevokeInviteDialog.test.tsx` |
| MODIFY | `web/src/test/mocks/handlers.ts` |

---

## Quality Gates

Before marking complete, verify:

```bash
cd web

# TypeScript
pnpm typecheck

# Lint
pnpm lint

# Tests
pnpm test:run

# Build
pnpm build
```

---

## Definition of Done

- [ ] Types updated with new fields and filters
- [ ] MemberActionsCell component created with all action logic
- [ ] RevokeInviteDialog component created
- [ ] Revoke invite API and hook added
- [ ] Members API updated to support new filter params
- [ ] useGARequestsCount hook added
- [ ] MembersPage refactored with 7 tabs
- [ ] Actions column always visible (same columns for all tabs)
- [ ] Invite button only shows for members with issueCount > 0
- [ ] GroundAdminCell component deleted
- [ ] i18n keys added
- [ ] All tests pass
- [ ] No TypeScript errors
- [ ] No lint errors
- [ ] Build passes

---

## Execution Notes for Agent

1. Read `web/CLAUDE.md` first for coding standards
2. Work through tasks in order (1-12)
3. After each major task, run `pnpm typecheck` to catch issues early
4. Run full quality gates at the end
5. If MSW handlers need mock data, reference existing mock members in handlers.ts
