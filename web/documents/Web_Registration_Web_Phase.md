# Web Registration - Web Admin Phase Implementation

**Feature:** Member Registration via Web with Admin Approval
**Phase:** Web Admin (2 of 3)
**Status:** ✅ Complete (2026-01-12)
**Dependencies:** Backend Phase must be completed first

---

## 1. Overview

This phase implements the React web admin changes to support member registration and admin approval workflow. It adds a public registration form and admin tools to approve/reject pending members.

### 1.1 Goals
- Add "Register as Member" link on login page
- Create public registration form page
- Update Members page with status filtering
- Add approve/reject actions for pending members
- Display pending members prominently

### 1.2 User Flows

**Member Registration:**
```
Login Page → "Register" link → Registration Form → Submit → Success Message → Return to Login
```

**Admin Approval:**
```
Login → Members Page → Filter "Pending" → Review Member → Approve/Reject → Email Sent (if approved)
```

---

## 2. Component Architecture

### 2.1 New Components

| Component | Type | Location | Purpose |
|-----------|------|----------|---------|
| `RegisterPage` | Page | `features/auth/RegisterPage.tsx` | Public registration page |
| `RegisterForm` | Molecule | `components/molecules/RegisterForm.tsx` | Registration form |
| `MemberApprovalActions` | Molecule | `features/members/components/MemberApprovalActions.tsx` | Approve/reject buttons |
| `MemberStatusFilter` | Molecule | `features/members/components/MemberStatusFilter.tsx` | Status filter tabs |

### 2.2 Modified Components

| Component | Changes |
|-----------|---------|
| `LoginPage` | Add "Register as Member" link |
| `MembersPage` | Add status filter, approval actions |
| `MembersTable` | Add action column, show email |
| `App.tsx` | Add `/register` route |

---

## 3. Registration Page

### 3.1 RegisterPage Component

**File:** `src/features/auth/RegisterPage.tsx`

```typescript
import { FC, useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, Link } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { RegisterForm, RegisterFormData } from '@/components/molecules/RegisterForm';
import { useRegisterMember } from './hooks';
import { useSectors } from './hooks';

export const RegisterPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const registerMutation = useRegisterMember();
  const { data: sectors, isLoading: sectorsLoading } = useSectors();

  const handleSubmit = useCallback(
    (data: RegisterFormData) => {
      registerMutation.mutate(data, {
        onSuccess: () => {
          setSuccessMessage(t('auth.registrationSuccess'));
        },
      });
    },
    [registerMutation, t]
  );

  // Show success state
  if (successMessage) {
    return (
      <AuthLayout>
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Alert severity="success" sx={{ mb: 3 }}>
            {successMessage}
          </Alert>
          <Typography variant="body1" sx={{ mb: 3 }}>
            {t('auth.registrationPendingInfo')}
          </Typography>
          <Button
            component={Link}
            to="/login"
            variant="contained"
          >
            {t('auth.backToLogin')}
          </Button>
        </Box>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout>
      <Typography variant="h5" component="h1" gutterBottom>
        {t('auth.registerTitle')}
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        {t('auth.registerSubtitle')}
      </Typography>

      <RegisterForm
        sectors={sectors ?? []}
        onSubmit={handleSubmit}
        isLoading={registerMutation.isPending || sectorsLoading}
        error={registerMutation.error?.message}
      />

      <Box sx={{ mt: 3, textAlign: 'center' }}>
        <Typography variant="body2" color="text.secondary">
          {t('auth.alreadyHaveAccount')}
        </Typography>
        <Button component={Link} to="/login" variant="text" size="small">
          {t('auth.loginLink')}
        </Button>
      </Box>
    </AuthLayout>
  );
};

export default RegisterPage;
```

### 3.2 RegisterForm Component

**File:** `src/components/molecules/RegisterForm.tsx`

```typescript
import { FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useForm, Controller } from 'react-hook-form';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Alert from '@mui/material/Alert';
import Typography from '@mui/material/Typography';
import LocationOnIcon from '@mui/icons-material/LocationOn';

import { Button } from '@/components/atoms/Button';
import { Sector } from '@/features/auth/types';

export interface RegisterFormData {
  email: string;
  firstName: string;
  surname: string;
  phone: string;
  address: string;
  latitude: number;
  longitude: number;
  sectorId: string;
}

interface RegisterFormProps {
  sectors: Sector[];
  onSubmit: (data: RegisterFormData) => void;
  isLoading?: boolean;
  error?: string;
}

export const RegisterForm: FC<RegisterFormProps> = ({
  sectors,
  onSubmit,
  isLoading = false,
  error,
}) => {
  const { t } = useTranslation();
  const [locationStatus, setLocationStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  const {
    control,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<RegisterFormData>({
    defaultValues: {
      email: '',
      firstName: '',
      surname: '',
      phone: '',
      address: '',
      latitude: 0,
      longitude: 0,
      sectorId: '',
    },
  });

  const handleGetLocation = () => {
    if (!navigator.geolocation) {
      setLocationStatus('error');
      return;
    }

    setLocationStatus('loading');
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setValue('latitude', position.coords.latitude);
        setValue('longitude', position.coords.longitude);
        setLocationStatus('success');
      },
      () => {
        setLocationStatus('error');
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  return (
    <Box
      component="form"
      onSubmit={handleSubmit(onSubmit)}
      sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}
    >
      {error && (
        <Alert severity="error" sx={{ mb: 1 }}>
          {error}
        </Alert>
      )}

      {/* Personal Information Section */}
      <Typography variant="subtitle2" color="text.secondary">
        {t('auth.personalInfo')}
      </Typography>

      <Box sx={{ display: 'flex', gap: 2 }}>
        <Controller
          name="firstName"
          control={control}
          rules={{
            required: t('validation.required'),
            maxLength: { value: 50, message: t('validation.maxLength', { max: 50 }) },
          }}
          render={({ field }) => (
            <TextField
              {...field}
              label={t('auth.firstName')}
              error={!!errors.firstName}
              helperText={errors.firstName?.message}
              disabled={isLoading}
              fullWidth
            />
          )}
        />
        <Controller
          name="surname"
          control={control}
          rules={{
            required: t('validation.required'),
            maxLength: { value: 50, message: t('validation.maxLength', { max: 50 }) },
          }}
          render={({ field }) => (
            <TextField
              {...field}
              label={t('auth.surname')}
              error={!!errors.surname}
              helperText={errors.surname?.message}
              disabled={isLoading}
              fullWidth
            />
          )}
        />
      </Box>

      {/* Contact Information Section */}
      <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 1 }}>
        {t('auth.contactInfo')}
      </Typography>

      <Controller
        name="email"
        control={control}
        rules={{
          required: t('validation.required'),
          pattern: {
            value: /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/,
            message: t('validation.invalidEmail'),
          },
        }}
        render={({ field }) => (
          <TextField
            {...field}
            type="email"
            label={t('auth.email')}
            error={!!errors.email}
            helperText={errors.email?.message || t('auth.emailHelp')}
            disabled={isLoading}
            fullWidth
          />
        )}
      />

      <Controller
        name="phone"
        control={control}
        rules={{
          required: t('validation.required'),
          pattern: {
            value: /^\+?[0-9]{10,15}$/,
            message: t('validation.invalidPhone'),
          },
        }}
        render={({ field }) => (
          <TextField
            {...field}
            type="tel"
            label={t('auth.phone')}
            placeholder="+27821234567"
            error={!!errors.phone}
            helperText={errors.phone?.message || t('auth.phoneHelp')}
            disabled={isLoading}
            fullWidth
          />
        )}
      />

      {/* Location Section */}
      <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 1 }}>
        {t('auth.locationInfo')}
      </Typography>

      <Controller
        name="address"
        control={control}
        rules={{
          required: t('validation.required'),
          maxLength: { value: 500, message: t('validation.maxLength', { max: 500 }) },
        }}
        render={({ field }) => (
          <TextField
            {...field}
            label={t('auth.address')}
            error={!!errors.address}
            helperText={errors.address?.message}
            disabled={isLoading}
            multiline
            rows={2}
            fullWidth
          />
        )}
      />

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Button
          type="button"
          variant="outlined"
          onClick={handleGetLocation}
          disabled={isLoading || locationStatus === 'loading'}
          startIcon={<LocationOnIcon />}
          sx={{ whiteSpace: 'nowrap' }}
        >
          {locationStatus === 'loading'
            ? t('auth.gettingLocation')
            : locationStatus === 'success'
            ? t('auth.locationCaptured')
            : t('auth.getLocation')}
        </Button>
        {locationStatus === 'error' && (
          <Typography variant="caption" color="error">
            {t('auth.locationError')}
          </Typography>
        )}
      </Box>

      {/* Hidden location fields - populated by geolocation */}
      <Controller
        name="latitude"
        control={control}
        rules={{ required: t('auth.locationRequired') }}
        render={({ field }) => <input type="hidden" {...field} />}
      />
      <Controller
        name="longitude"
        control={control}
        rules={{ required: t('auth.locationRequired') }}
        render={({ field }) => <input type="hidden" {...field} />}
      />

      {/* Sector Selection */}
      <Controller
        name="sectorId"
        control={control}
        rules={{ required: t('validation.required') }}
        render={({ field }) => (
          <TextField
            {...field}
            select
            label={t('auth.sector')}
            error={!!errors.sectorId}
            helperText={errors.sectorId?.message || t('auth.sectorHelp')}
            disabled={isLoading || sectors.length === 0}
            fullWidth
          >
            {sectors.map((sector) => (
              <MenuItem key={sector.id} value={sector.id}>
                {sector.name}
              </MenuItem>
            ))}
          </TextField>
        )}
      />

      {(errors.latitude || errors.longitude) && (
        <Alert severity="warning">
          {t('auth.locationRequired')}
        </Alert>
      )}

      <Button
        type="submit"
        variant="contained"
        size="large"
        isLoading={isLoading}
        disabled={isLoading}
        sx={{ mt: 2 }}
      >
        {t('auth.submitRegistration')}
      </Button>
    </Box>
  );
};

export default RegisterForm;
```

---

## 4. Login Page Updates

### 4.1 Add Register Link

**File:** `src/features/auth/LoginPage.tsx`

Add after the login form:

```typescript
import { Link } from 'react-router-dom';
import Divider from '@mui/material/Divider';

// ... existing login form code ...

// Add after login form, before closing AuthLayout
<Divider sx={{ my: 3 }}>
  <Typography variant="body2" color="text.secondary">
    {t('auth.or')}
  </Typography>
</Divider>

<Box sx={{ textAlign: 'center' }}>
  <Typography variant="body2" color="text.secondary" gutterBottom>
    {t('auth.newMember')}
  </Typography>
  <Button
    component={Link}
    to="/register"
    variant="outlined"
    fullWidth
  >
    {t('auth.registerAsNewMember')}
  </Button>
</Box>
```

---

## 5. Members Page Updates

### 5.1 Updated MembersPage

**File:** `src/features/members/MembersPage.tsx`

```typescript
import { FC, useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSearchParams } from 'react-router-dom';
import Box from '@mui/material/Box';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Badge from '@mui/material/Badge';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { Pagination } from '@/components/molecules/Pagination';
import { LoadingSkeleton } from '@/components/atoms/LoadingSkeleton';
import { ErrorState } from '@/components/atoms/ErrorState';
import { EmptyState } from '@/components/atoms/EmptyState';

import { MembersTable } from './components/MembersTable';
import { MemberApprovalDialog } from './components/MemberApprovalDialog';
import { useMembers, useApproveMember, useRejectMember, usePendingMemberCount } from './hooks';
import { MemberStatus, MemberListItem } from './types';

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

    const mutation = approvalDialog.action === 'approve' ? approveMutation : rejectMutation;

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
          { label: t('nav.dashboard'), href: '/' },
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
          <Tab
            value="all"
            label={t('members.filterAll')}
          />
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
          <Tab
            value="active"
            label={t('members.filterActive')}
          />
          <Tab
            value="suspended"
            label={t('members.filterSuspended')}
          />
        </Tabs>
      </Box>

      <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 2 }}>
        {isLoading && <LoadingSkeleton variant="rect" height={400} />}

        {error && (
          <ErrorState
            title={t('common.error')}
            message={error.message}
            onRetry={refetch}
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
              showApprovalActions={statusFilter === 'pending_approval' || statusFilter === 'all'}
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
```

### 5.2 MemberApprovalDialog Component

**New File:** `src/features/members/components/MemberApprovalDialog.tsx`

```typescript
import { FC } from 'react';
import { useTranslation } from 'react-i18next';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogActions from '@mui/material/DialogActions';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';

import { Button } from '@/components/atoms/Button';
import { MemberListItem } from '../types';

interface MemberApprovalDialogProps {
  open: boolean;
  action: 'approve' | 'reject';
  member: MemberListItem | null;
  isLoading: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export const MemberApprovalDialog: FC<MemberApprovalDialogProps> = ({
  open,
  action,
  member,
  isLoading,
  onConfirm,
  onCancel,
}) => {
  const { t } = useTranslation();

  if (!member) return null;

  const isApprove = action === 'approve';
  const title = isApprove ? t('members.approveTitle') : t('members.rejectTitle');
  const confirmText = isApprove ? t('members.approve') : t('members.reject');
  const confirmColor = isApprove ? 'success' : 'error';

  return (
    <Dialog
      open={open}
      onClose={onCancel}
      maxWidth="sm"
      fullWidth
    >
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
          <Avatar sx={{ width: 56, height: 56, bgcolor: 'primary.main' }}>
            {member.firstName.charAt(0)}
            {member.surname.charAt(0)}
          </Avatar>
          <Box>
            <Typography variant="h6">
              {member.firstName} {member.surname}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {member.email}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {member.phoneNumber}
            </Typography>
          </Box>
        </Box>

        <DialogContentText>
          {isApprove
            ? t('members.approveConfirmation')
            : t('members.rejectConfirmation')}
        </DialogContentText>

        {isApprove && (
          <Typography variant="body2" color="info.main" sx={{ mt: 2 }}>
            {t('members.approveEmailNote')}
          </Typography>
        )}

        {!isApprove && (
          <Typography variant="body2" color="warning.main" sx={{ mt: 2 }}>
            {t('members.rejectWarning')}
          </Typography>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel} disabled={isLoading}>
          {t('common.cancel')}
        </Button>
        <Button
          onClick={onConfirm}
          color={confirmColor}
          variant="contained"
          isLoading={isLoading}
        >
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default MemberApprovalDialog;
```

### 5.3 Updated MembersTable

**File:** `src/features/members/components/MembersTable.tsx`

Add email column and action buttons:

```typescript
import { FC, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import AssignmentIcon from '@mui/icons-material/Assignment';

import { DataTable, Column } from '@/components/organisms/DataTable';
import { MemberStatusBadge } from '@/components/molecules/MemberStatusBadge';
import { MemberListItem } from '../types';
import { useFormatDate } from '@/shared/hooks/useFormatDate';

interface MembersTableProps {
  members: MemberListItem[];
  showApprovalActions?: boolean;
  onApprove?: (member: MemberListItem) => void;
  onReject?: (member: MemberListItem) => void;
  onRowClick?: (member: MemberListItem) => void;
}

export const MembersTable: FC<MembersTableProps> = ({
  members,
  showApprovalActions = false,
  onApprove,
  onReject,
  onRowClick,
}) => {
  const { t } = useTranslation();
  const { formatDate } = useFormatDate();

  const columns: Column<MemberListItem>[] = useMemo(
    () => [
      {
        key: 'name',
        header: t('members.name'),
        render: (member) => (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Avatar
              sx={{
                width: 40,
                height: 40,
                bgcolor: member.status === 'pending_approval' ? 'warning.main' : 'primary.main',
              }}
            >
              {member.firstName.charAt(0)}
              {member.surname.charAt(0)}
            </Avatar>
            <Box>
              <Typography variant="body2" fontWeight={500}>
                {member.firstName} {member.surname}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {member.email}
              </Typography>
            </Box>
          </Box>
        ),
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
        header: t('members.joined'),
        width: '130px',
        render: (member) => (
          <Typography variant="body2" color="text.secondary">
            {formatDate(member.joinedAt)}
          </Typography>
        ),
      },
      // Approval actions column (only shown when showApprovalActions is true)
      ...(showApprovalActions
        ? [
            {
              key: 'actions',
              header: t('members.actions'),
              width: '120px',
              align: 'center' as const,
              render: (member: MemberListItem) =>
                member.status === 'pending_approval' ? (
                  <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                    <Tooltip title={t('members.approve')}>
                      <IconButton
                        color="success"
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation();
                          onApprove?.(member);
                        }}
                      >
                        <CheckCircleIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={t('members.reject')}>
                      <IconButton
                        color="error"
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation();
                          onReject?.(member);
                        }}
                      >
                        <CancelIcon />
                      </IconButton>
                    </Tooltip>
                  </Box>
                ) : null,
            },
          ]
        : []),
    ],
    [t, formatDate, showApprovalActions, onApprove, onReject]
  );

  return (
    <DataTable
      columns={columns}
      data={members}
      keyExtractor={(member) => member.id}
      onRowClick={onRowClick ? (member) => onRowClick(member) : undefined}
    />
  );
};

export default MembersTable;
```

---

## 6. API Layer Updates

### 6.1 Auth API

**File:** `src/features/auth/api.ts`

Add registration endpoint:

```typescript
import { apiClient } from '@/lib/api-client';
import { LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, Sector } from './types';

export const authApi = {
  login: (data: LoginRequest) =>
    apiClient.post<LoginResponse>('/auth/admin/login', data).then((r) => r.data),

  logout: () => apiClient.post('/auth/logout'),

  // NEW: Member registration
  registerMember: (data: RegisterRequest) =>
    apiClient.post<RegisterResponse>('/auth/register/web', data).then((r) => r.data),

  getSectors: () =>
    apiClient.get<{ items: Sector[] }>('/sectors').then((r) => r.data.items),
};
```

### 6.2 Members API

**File:** `src/features/members/api.ts`

Add approve/reject endpoints:

```typescript
import { apiClient } from '@/lib/api-client';
import { PaginatedResponse } from '@/shared/types/common';
import { MemberListItem, MemberFilterParams, MemberApproveResponse } from './types';

export const membersApi = {
  getAll: (sectorId: string, params?: MemberFilterParams) =>
    apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', {
        params: { sectorId, ...params },
      })
      .then((r) => r.data),

  // NEW: Approve pending member
  approve: (id: string) =>
    apiClient.post<MemberApproveResponse>(`/admin/members/${id}/approve`).then((r) => r.data),

  // NEW: Reject pending member
  reject: (id: string) =>
    apiClient.delete(`/admin/members/${id}`),

  // NEW: Get pending member count
  getPendingCount: (sectorId: string) =>
    apiClient
      .get<{ count: number }>('/admin/members/pending-count', {
        params: { sectorId },
      })
      .then((r) => r.data.count),
};
```

### 6.3 Auth Hooks

**File:** `src/features/auth/hooks.ts`

Add registration hook:

```typescript
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { authApi } from './api';
import { RegisterRequest } from './types';

// ... existing hooks ...

// NEW: Register member mutation
export function useRegisterMember() {
  return useMutation({
    mutationFn: (data: RegisterRequest) => authApi.registerMember(data),
  });
}

// Sectors query (move from existing or add)
export function useSectors() {
  return useQuery({
    queryKey: ['sectors'],
    queryFn: () => authApi.getSectors(),
    staleTime: 1000 * 60 * 60, // 1 hour - sectors rarely change
  });
}
```

### 6.4 Members Hooks

**File:** `src/features/members/hooks.ts`

Add approval hooks:

```typescript
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { membersApi } from './api';
import { useAuth } from '@/shared/hooks/useAuth';
import { MemberFilterParams } from './types';

// ... existing useMembers hook ...

// NEW: Approve member mutation
export function useApproveMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => membersApi.approve(id),
    onSuccess: () => {
      // Invalidate members list to refetch
      queryClient.invalidateQueries({ queryKey: ['members'] });
      // Also invalidate pending count
      queryClient.invalidateQueries({ queryKey: ['members', 'pending-count'] });
    },
  });
}

// NEW: Reject member mutation
export function useRejectMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => membersApi.reject(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['members'] });
      queryClient.invalidateQueries({ queryKey: ['members', 'pending-count'] });
    },
  });
}

// NEW: Get pending member count
export function usePendingMemberCount() {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['members', 'pending-count', admin?.sectorId],
    queryFn: () => membersApi.getPendingCount(admin!.sectorId),
    enabled: !!admin?.sectorId,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
}
```

---

## 7. Type Definitions

### 7.1 Auth Types

**File:** `src/features/auth/types.ts`

Add new types:

```typescript
// ... existing types ...

// NEW: Registration request
export interface RegisterRequest {
  email: string;
  firstName: string;
  surname: string;
  phone: string;
  address: string;
  latitude: number;
  longitude: number;
  sectorId: string;
}

// NEW: Registration response
export interface RegisterResponse {
  message: string;
  memberId: string;
}
```

### 7.2 Member Types

**File:** `src/features/members/types.ts`

Update types:

```typescript
// Update MemberStatus to include pending_approval
export type MemberStatus = 'active' | 'pending_approval' | 'suspended';

// Update status labels
export const MEMBER_STATUS_LABELS: Record<MemberStatus, string> = {
  active: 'Active',
  pending_approval: 'Pending Approval',
  suspended: 'Suspended',
};

// Update MemberListItem to include email
export interface MemberListItem {
  id: string;
  firstName: string;
  surname: string;
  email: string;        // NEW
  phoneNumber: string;
  address: string;
  status: MemberStatus;
  issueCount: number;
  joinedAt: string;
}

// Update filter params
export interface MemberFilterParams {
  sectorId?: string;
  search?: string;
  status?: MemberStatus;
  page?: number;
  limit?: number;
}

// NEW: Approve response
export interface MemberApproveResponse {
  memberId: string;
  email: string;
  message: string;
}
```

### 7.3 Update MemberStatusBadge

**File:** `src/components/molecules/MemberStatusBadge.tsx`

Add pending_approval styling:

```typescript
import { FC } from 'react';
import Chip from '@mui/material/Chip';
import { MemberStatus, MEMBER_STATUS_LABELS } from '@/features/members/types';

const statusColors: Record<MemberStatus, 'success' | 'warning' | 'error' | 'default'> = {
  active: 'success',
  pending_approval: 'warning',
  suspended: 'error',
};

interface MemberStatusBadgeProps {
  status: MemberStatus;
}

export const MemberStatusBadge: FC<MemberStatusBadgeProps> = ({ status }) => (
  <Chip
    label={MEMBER_STATUS_LABELS[status]}
    color={statusColors[status]}
    size="small"
    variant="outlined"
  />
);
```

---

## 8. Routing Updates

**File:** `src/App.tsx`

Add register route:

```typescript
import { lazy, Suspense } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from '@/components/guards/ProtectedRoute';
import { LoadingPage } from '@/components/atoms/LoadingPage';

// Lazy load pages
const LoginPage = lazy(() => import('@/features/auth/LoginPage'));
const RegisterPage = lazy(() => import('@/features/auth/RegisterPage')); // NEW
const DashboardPage = lazy(() => import('@/features/dashboard/DashboardPage'));
const MembersPage = lazy(() => import('@/features/members/MembersPage'));
// ... other pages

function App() {
  return (
    <Suspense fallback={<LoadingPage />}>
      <Routes>
        {/* Public routes */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />  {/* NEW */}

        {/* Protected routes */}
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/members"
          element={
            <ProtectedRoute>
              <MembersPage />
            </ProtectedRoute>
          }
        />
        {/* ... other routes ... */}

        {/* Catch-all */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Suspense>
  );
}

export default App;
```

---

## 9. Translations

**File:** `src/locales/en/translation.json`

Add new translation keys:

```json
{
  "auth": {
    "registerTitle": "Register as a Community Member",
    "registerSubtitle": "Join your community to report and track municipal service issues",
    "personalInfo": "Personal Information",
    "contactInfo": "Contact Information",
    "locationInfo": "Location Information",
    "firstName": "First Name",
    "surname": "Surname",
    "email": "Email Address",
    "emailHelp": "You'll use this email to log in to the mobile app",
    "phone": "Phone Number",
    "phoneHelp": "For contact purposes",
    "address": "Street Address",
    "sector": "Community/Ward",
    "sectorHelp": "Select the community you belong to",
    "getLocation": "Get My Location",
    "gettingLocation": "Getting location...",
    "locationCaptured": "Location captured",
    "locationError": "Could not get location. Please try again.",
    "locationRequired": "Please capture your location using the button above",
    "submitRegistration": "Submit Registration",
    "registrationSuccess": "Registration Submitted Successfully!",
    "registrationPendingInfo": "Your registration has been submitted. You will receive an email with login instructions once an administrator approves your registration.",
    "backToLogin": "Back to Login",
    "alreadyHaveAccount": "Already have an account?",
    "loginLink": "Log in here",
    "or": "or",
    "newMember": "New to the community?",
    "registerAsNewMember": "Register as a New Member"
  },
  "members": {
    "filterByStatus": "Filter by status",
    "filterAll": "All Members",
    "filterPending": "Pending Approval",
    "filterActive": "Active",
    "filterSuspended": "Suspended",
    "actions": "Actions",
    "approve": "Approve",
    "reject": "Reject",
    "approveTitle": "Approve Member Registration",
    "rejectTitle": "Reject Member Registration",
    "approveConfirmation": "Are you sure you want to approve this member's registration?",
    "rejectConfirmation": "Are you sure you want to reject this member's registration?",
    "approveEmailNote": "A welcome email with login credentials will be sent to the member.",
    "rejectWarning": "This will permanently delete the registration. The member will need to register again if they wish to join.",
    "noPendingMembers": "No pending registrations to review"
  },
  "validation": {
    "required": "This field is required",
    "maxLength": "Maximum {{max}} characters allowed",
    "invalidEmail": "Please enter a valid email address",
    "invalidPhone": "Please enter a valid phone number (e.g., +27821234567)"
  }
}
```

---

## 10. Testing Requirements

### 10.1 Component Tests

**File:** `src/features/auth/RegisterPage.test.tsx`

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RegisterPage } from './RegisterPage';
import { TestProviders } from '@/test/TestProviders';

describe('RegisterPage', () => {
  it('renders registration form', () => {
    render(<RegisterPage />, { wrapper: TestProviders });

    expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
  });

  it('validates required fields', async () => {
    render(<RegisterPage />, { wrapper: TestProviders });

    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(screen.getAllByText(/required/i).length).toBeGreaterThan(0);
    });
  });

  it('shows success message after registration', async () => {
    // Mock successful registration
    render(<RegisterPage />, { wrapper: TestProviders });

    // Fill form and submit...
    // Verify success message appears
  });
});
```

**File:** `src/features/members/MembersPage.test.tsx`

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MembersPage } from './MembersPage';
import { TestProviders } from '@/test/TestProviders';

describe('MembersPage', () => {
  it('renders status filter tabs', () => {
    render(<MembersPage />, { wrapper: TestProviders });

    expect(screen.getByRole('tab', { name: /all/i })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: /pending/i })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: /active/i })).toBeInTheDocument();
  });

  it('shows approval actions for pending members', async () => {
    // Mock pending members data
    render(<MembersPage />, { wrapper: TestProviders });

    await userEvent.click(screen.getByRole('tab', { name: /pending/i }));

    await waitFor(() => {
      expect(screen.getAllByTitle(/approve/i).length).toBeGreaterThan(0);
    });
  });

  it('opens confirmation dialog on approve click', async () => {
    // Test approve button opens dialog
  });
});
```

---

## 11. Implementation Checklist

Use this checklist with `/dev-cycle` for implementation:

### Pages & Components
- [x] Create `RegisterPage.tsx` ✅ (2026-01-09)
- [x] Create `RegisterForm.tsx` ✅ (2026-01-09)
- [x] Update `LoginPage.tsx` - add register link ✅ (2026-01-09)
- [x] Update `MembersPage.tsx` - add filters and actions ✅ (2026-01-09)
- [x] Create `MemberApprovalDialog.tsx` ✅ (2026-01-09)
- [x] Update `MembersTable.tsx` - add email and actions column ✅ (2026-01-09)
- [x] Update `MemberStatusBadge.tsx` - add pending_approval ✅ (2026-01-09)

### API & Hooks
- [x] Update `auth/api.ts` - add registerMember ✅ (2026-01-09)
- [x] Update `members/api.ts` - add approve, reject, getPendingCount ✅ (2026-01-09)
- [x] Update `auth/hooks.ts` - add useRegisterMember, useSectors ✅ (2026-01-09)
- [x] Update `members/hooks.ts` - add useApproveMember, useRejectMember, usePendingMemberCount ✅ (2026-01-09)

### Types
- [x] Update `auth/types.ts` - add RegisterRequest, RegisterResponse ✅ (2026-01-09)
- [x] Update `members/types.ts` - add pending_approval status, email field ✅ (2026-01-09)

### Routing & Config
- [x] Update `App.tsx` - add /register route ✅ (2026-01-09)
- [x] Add translations to `en/translation.json` ✅ (2026-01-09)

### Testing
- [x] Write tests for RegisterPage ✅ (2026-01-09 - 10 tests)
- [x] Write tests for RegisterForm ✅ (2026-01-09 - 16 tests)
- [x] Write tests for LoginPage (register link) ✅ (2026-01-09 - 7 tests)
- [x] Write tests for MembersPage (updated) ✅ (2026-01-09 - 12 tests)
- [x] Write tests for MemberApprovalDialog ✅ (2026-01-09 - 16 tests)
- [x] Write tests for MembersTable ✅ (2026-01-09 - 14 tests)
- [x] Write tests for auth/api.ts ✅ (2026-01-09 - 9 tests)
- [x] Write tests for members/api.ts ✅ (2026-01-09 - 15 tests)
- [x] Write tests for auth/hooks.ts ✅ (2026-01-09 - 10 tests)
- [x] Write tests for members/hooks.ts ✅ (2026-01-09 - 19 tests)
- [x] E2E test for registration flow ✅ (2026-01-12 - 13 tests)

---

## 12. API Contract Reference

### Public Endpoints

```
GET /api/v1/sectors
Response: { items: [{ id, name, center }] }

POST /api/v1/auth/register/web
Request: { email, firstName, surname, phone, address, latitude, longitude, sectorId }
Response: 201 { message, memberId }
Errors: 400 (validation), 409 (email exists)
```

### Protected Endpoints (Admin JWT)

```
GET /api/v1/admin/members?sectorId=...&status=...&page=1&limit=20
Response: { items: [...], pagination: { page, limit, totalItems, totalPages } }

GET /api/v1/admin/members/pending-count?sectorId=...
Response: { count: number }

POST /api/v1/admin/members/{id}/approve
Response: 200 { memberId, email, message }
Errors: 400 (wrong status), 404 (not found)

DELETE /api/v1/admin/members/{id}
Response: 204
Errors: 400 (wrong status), 404 (not found)
```

---

*Document ready for `/dev-cycle` implementation. Ensure backend phase is complete before starting.*
