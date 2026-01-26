# Handoff: Web

**Feature:** pod-chief-bootstrap
**Milestone:** [#2](https://github.com/ossewawiel/munserv/milestone/2)
**Stories:** W22, W23, W24, W26, W27, W28, W29, W30
**Platform:** React + TypeScript + MUI + React Query

---

## Context

Enable super user to bootstrap a fresh pod by creating the first Pod Chief via a web interface. The Pod Chief then completes an onboarding flow (change password, optional profile). After onboarding, support access can be granted to the super user for debugging/maintenance from Pod Settings.

---

## Phase 1: Bootstrap Feature Module (W22, W23, W24)

### Architecture: Single Login Page with Role-Based Routing

**No separate bootstrap login page is needed.** The existing `/login` page handles all admin logins:
1. User enters credentials on existing login page
2. Backend returns response with `role` and `bootstrapStatus`
3. Frontend routes based on the response:
   - `role: "SUPER_USER"` → `/bootstrap/create-pod-chief`
   - `role: *` with `onboardingStatus: "pending"` → `/onboarding/change-password`
   - `role: *` with `onboardingStatus: "active"` → `/dashboard`

### Files to Create

#### `features/bootstrap/types.ts`

```typescript
export type BootstrapStatus = 'requires_bootstrap' | 'pod_chief_pending' | 'bootstrapped';

export interface BootstrapStatusResponse {
  status: BootstrapStatus;
  canBootstrap: boolean;
  message: string;
}

export interface CreatePodChiefRequest {
  email: string;
  displayName: string;
}

export interface CreatePodChiefResponse {
  adminId: string;
  email: string;
  displayName: string;
  temporaryPassword: string;
  message: string;
}
```

#### `features/bootstrap/api.ts`

```typescript
import { apiClient } from '@/lib/api-client';
import type {
  BootstrapStatusResponse,
  CreatePodChiefRequest,
  CreatePodChiefResponse,
} from './types';

export const bootstrapApi = {
  getStatus: () =>
    apiClient.get<BootstrapStatusResponse>('/api/v1/bootstrap/status').then((r) => r.data),

  createPodChief: (data: CreatePodChiefRequest) =>
    apiClient.post<CreatePodChiefResponse>('/api/v1/bootstrap/pod-chief', data).then((r) => r.data),
};
```

#### `features/bootstrap/hooks.ts`

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { bootstrapApi } from './api';
import type { CreatePodChiefRequest } from './types';

export function useBootstrapStatus() {
  return useQuery({
    queryKey: ['bootstrap', 'status'],
    queryFn: bootstrapApi.getStatus,
    staleTime: 30000, // 30 seconds
  });
}

export function useCreatePodChief() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePodChiefRequest) => bootstrapApi.createPodChief(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bootstrap'] });
    },
  });
}
```

### Files to Modify

#### `features/auth/LoginPage.tsx` - Add role-based routing

Update the existing login page to handle super user responses:

```typescript
// In the login success handler, add routing logic:

const handleLoginSuccess = (response: AdminLoginResponse) => {
  // Store tokens
  localStorage.setItem('token', response.tokens.accessToken);
  localStorage.setItem('refreshToken', response.tokens.refreshToken);

  const { admin, bootstrapStatus } = response.profile;

  // Route based on role and status
  if (admin.role === 'SUPER_USER') {
    // Super user - go to create Pod Chief
    localStorage.setItem('isSuperUser', 'true');
    navigate('/bootstrap/create-pod-chief', { replace: true });
    return;
  }

  // Regular admin - check onboarding status
  if (admin.onboardingStatus === 'pending') {
    navigate('/onboarding/change-password', { replace: true });
    return;
  }

  if (admin.onboardingStatus === 'password_changed') {
    navigate('/onboarding/complete-profile', { replace: true });
    return;
  }

  // Fully onboarded - go to dashboard
  navigate('/', { replace: true });
};
```

#### `features/auth/types.ts` - Update response types

```typescript
// Update AdminUser interface
export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  role: string;
  level: string;
  podId: string | null;
  wardId: string | null;
  sectorId: string | null;
  onboardingStatus: string | null;  // ADD THIS
}

// Update AdminProfile interface
export interface AdminProfile {
  admin: AdminUser;
  sector: AdminSector | null;
  bootstrapStatus?: string;  // ADD THIS - only set for super user
}
```

### Files to Create

#### `features/bootstrap/CreatePodChiefPage.tsx`

```typescript
import { type FC, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { useCreatePodChief } from './hooks';

export const CreatePodChiefPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const createMutation = useCreatePodChief();

  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [emailError, setEmailError] = useState('');
  const [nameError, setNameError] = useState('');
  const [temporaryPassword, setTemporaryPassword] = useState<string | null>(null);
  const [passwordCopied, setPasswordCopied] = useState(false);

  const validateEmail = (value: string): boolean => {
    if (!value.trim()) {
      setEmailError(t('bootstrap.emailRequired'));
      return false;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      setEmailError(t('bootstrap.emailInvalid'));
      return false;
    }
    setEmailError('');
    return true;
  };

  const validateName = (value: string): boolean => {
    if (!value.trim()) {
      setNameError(t('bootstrap.displayNameRequired'));
      return false;
    }
    setNameError('');
    return true;
  };

  const handleSubmit = () => {
    const isEmailValid = validateEmail(email);
    const isNameValid = validateName(displayName);

    if (isEmailValid && isNameValid) {
      createMutation.mutate(
        { email: email.trim(), displayName: displayName.trim() },
        {
          onSuccess: (data) => {
            setTemporaryPassword(data.temporaryPassword);
          },
        }
      );
    }
  };

  const handleCopyPassword = async () => {
    if (temporaryPassword) {
      await navigator.clipboard.writeText(temporaryPassword);
      setPasswordCopied(true);
    }
  };

  const handleClose = () => {
    // Clear super user session and redirect to login
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('isSuperUser');
    navigate('/login', { replace: true });
  };

  // Success dialog
  if (temporaryPassword) {
    return (
      <Dialog open onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: 'success.main', color: 'common.white' }}>
          {t('bootstrap.podChiefCreated')}
        </DialogTitle>
        <DialogContent sx={{ pt: 3 }}>
          <Alert severity="warning" sx={{ mb: 2 }}>
            {t('bootstrap.passwordNote')}
          </Alert>
          <Typography variant="subtitle2" gutterBottom>
            {t('bootstrap.temporaryPassword')}
          </Typography>
          <TextField
            fullWidth
            value={temporaryPassword}
            slotProps={{
              input: {
                readOnly: true,
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={handleCopyPassword} edge="end">
                      <ContentCopyIcon />
                    </IconButton>
                  </InputAdornment>
                ),
              },
            }}
            sx={{ mb: 1 }}
          />
          {passwordCopied && (
            <Typography variant="caption" color="success.main">
              {t('bootstrap.passwordCopied')}
            </Typography>
          )}
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            {t('bootstrap.emailSent')}
          </Typography>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button variant="contained" onClick={handleClose}>
            {t('bootstrap.goToLogin')}
          </Button>
        </DialogActions>
      </Dialog>
    );
  }

  return (
    <AuthLayout>
      <Typography variant="h5" gutterBottom>
        {t('bootstrap.createPodChief')}
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        {t('bootstrap.createPodChiefDescription')}
      </Typography>

      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {createMutation.error && (
          <Alert severity="error">{t('bootstrap.createError')}</Alert>
        )}

        <TextField
          autoFocus
          label={t('common.email')}
          type="email"
          fullWidth
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (emailError) validateEmail(e.target.value);
          }}
          onBlur={() => validateEmail(email)}
          error={!!emailError}
          helperText={emailError}
          disabled={createMutation.isPending}
        />

        <TextField
          label={t('bootstrap.displayName')}
          fullWidth
          value={displayName}
          onChange={(e) => {
            setDisplayName(e.target.value);
            if (nameError) validateName(e.target.value);
          }}
          onBlur={() => validateName(displayName)}
          error={!!nameError}
          helperText={nameError}
          disabled={createMutation.isPending}
        />

        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={createMutation.isPending}
          sx={{ mt: 2 }}
        >
          {createMutation.isPending ? (
            <CircularProgress size={24} />
          ) : (
            t('bootstrap.createPodChief')
          )}
        </Button>
      </Box>
    </AuthLayout>
  );
};

export default CreatePodChiefPage;
```

---

## Phase 2: Onboarding Feature Module (W26, W27)

### Files to Create

#### `features/onboarding/types.ts`

```typescript
export type OnboardingStatus = 'pending' | 'password_changed' | 'profile_complete' | 'active';

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

export interface CompleteProfileRequest {
  displayName: string;
  knownAs?: string;
  contactPhone?: string;
  address?: string;
}

export interface AdminProfile {
  id: string;
  email: string;
  displayName: string;
  knownAs?: string;
  contactPhone?: string;
  address?: string;
  onboardingStatus: OnboardingStatus;
}
```

#### `features/onboarding/api.ts`

```typescript
import { apiClient } from '@/lib/api-client';
import type { ChangePasswordRequest, CompleteProfileRequest, AdminProfile } from './types';

export const onboardingApi = {
  changePassword: (data: ChangePasswordRequest) =>
    apiClient.post('/api/v1/admin/change-password', data).then((r) => r.data),

  completeProfile: (data: CompleteProfileRequest) =>
    apiClient.post<AdminProfile>('/api/v1/admin/complete-profile', data).then((r) => r.data),

  skipProfile: () =>
    apiClient.post<AdminProfile>('/api/v1/admin/skip-profile').then((r) => r.data),

  getProfile: () =>
    apiClient.get<AdminProfile>('/api/v1/admin/me').then((r) => r.data),
};
```

#### `features/onboarding/hooks.ts`

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { onboardingApi } from './api';
import type { ChangePasswordRequest, CompleteProfileRequest } from './types';

export function useAdminProfile() {
  return useQuery({
    queryKey: ['admin', 'profile'],
    queryFn: onboardingApi.getProfile,
  });
}

export function useChangePassword() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ChangePasswordRequest) => onboardingApi.changePassword(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'profile'] });
    },
  });
}

export function useCompleteProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CompleteProfileRequest) => onboardingApi.completeProfile(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'profile'] });
    },
  });
}

export function useSkipProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => onboardingApi.skipProfile(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'profile'] });
    },
  });
}
```

#### `features/onboarding/ChangePasswordPage.tsx`

```typescript
import { type FC, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { useChangePassword } from './hooks';

const PASSWORD_REQUIREMENTS = [
  { key: 'minLength', test: (p: string) => p.length >= 8 },
  { key: 'uppercase', test: (p: string) => /[A-Z]/.test(p) },
  { key: 'lowercase', test: (p: string) => /[a-z]/.test(p) },
  { key: 'number', test: (p: string) => /[0-9]/.test(p) },
];

export const ChangePasswordPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const changeMutation = useChangePassword();

  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const passwordsMatch = newPassword === confirmPassword;
  const allRequirementsMet = PASSWORD_REQUIREMENTS.every((r) => r.test(newPassword));
  const canSubmit = currentPassword && newPassword && confirmPassword && passwordsMatch && allRequirementsMet;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;

    changeMutation.mutate(
      { currentPassword, newPassword },
      {
        onSuccess: () => {
          navigate('/onboarding/complete-profile');
        },
      }
    );
  };

  return (
    <AuthLayout>
      <Typography variant="h5" gutterBottom>
        {t('onboarding.changePassword')}
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        {t('onboarding.changePasswordDescription')}
      </Typography>

      <Box component="form" onSubmit={handleSubmit}>
        {changeMutation.error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {t('onboarding.changePasswordError')}
          </Alert>
        )}

        <TextField
          label={t('onboarding.currentPassword')}
          type="password"
          fullWidth
          value={currentPassword}
          onChange={(e) => setCurrentPassword(e.target.value)}
          disabled={changeMutation.isPending}
          sx={{ mb: 2 }}
        />

        <TextField
          label={t('onboarding.newPassword')}
          type="password"
          fullWidth
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          disabled={changeMutation.isPending}
          sx={{ mb: 2 }}
        />

        <TextField
          label={t('onboarding.confirmPassword')}
          type="password"
          fullWidth
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          error={confirmPassword !== '' && !passwordsMatch}
          helperText={confirmPassword !== '' && !passwordsMatch ? t('onboarding.passwordsMustMatch') : ''}
          disabled={changeMutation.isPending}
          sx={{ mb: 2 }}
        />

        <Typography variant="subtitle2" sx={{ mb: 1 }}>
          {t('onboarding.passwordRequirements')}
        </Typography>
        <List dense>
          {PASSWORD_REQUIREMENTS.map((req) => {
            const met = req.test(newPassword);
            return (
              <ListItem key={req.key} disablePadding>
                <ListItemIcon sx={{ minWidth: 32 }}>
                  {met ? (
                    <CheckCircleIcon color="success" fontSize="small" />
                  ) : (
                    <CancelIcon color="disabled" fontSize="small" />
                  )}
                </ListItemIcon>
                <ListItemText
                  primary={t(`onboarding.requirements.${req.key}`)}
                  primaryTypographyProps={{
                    variant: 'body2',
                    color: met ? 'text.primary' : 'text.secondary',
                  }}
                />
              </ListItem>
            );
          })}
        </List>

        <Button
          type="submit"
          variant="contained"
          fullWidth
          disabled={!canSubmit || changeMutation.isPending}
          sx={{ mt: 2 }}
        >
          {changeMutation.isPending ? <CircularProgress size={24} /> : t('onboarding.changePasswordButton')}
        </Button>
      </Box>
    </AuthLayout>
  );
};

export default ChangePasswordPage;
```

#### `features/onboarding/CompleteProfilePage.tsx`

```typescript
import { type FC, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { useAdminProfile, useCompleteProfile, useSkipProfile } from './hooks';

export const CompleteProfilePage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { data: profile } = useAdminProfile();
  const completeMutation = useCompleteProfile();
  const skipMutation = useSkipProfile();

  const [displayName, setDisplayName] = useState(profile?.displayName ?? '');
  const [knownAs, setKnownAs] = useState(profile?.knownAs ?? '');
  const [contactPhone, setContactPhone] = useState(profile?.contactPhone ?? '');
  const [address, setAddress] = useState(profile?.address ?? '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    completeMutation.mutate(
      { displayName, knownAs: knownAs || undefined, contactPhone: contactPhone || undefined, address: address || undefined },
      {
        onSuccess: () => {
          navigate('/', { replace: true });
        },
      }
    );
  };

  const handleSkip = () => {
    skipMutation.mutate(undefined, {
      onSuccess: () => {
        navigate('/', { replace: true });
      },
    });
  };

  const isLoading = completeMutation.isPending || skipMutation.isPending;

  return (
    <AuthLayout>
      <Typography variant="h5" gutterBottom>
        {t('onboarding.completeProfile')}
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        {t('onboarding.completeProfileDescription')}
      </Typography>

      <Box component="form" onSubmit={handleSubmit}>
        {(completeMutation.error || skipMutation.error) && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {t('onboarding.profileError')}
          </Alert>
        )}

        <TextField
          label={t('onboarding.displayName')}
          fullWidth
          required
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          disabled={isLoading}
          sx={{ mb: 2 }}
        />

        <TextField
          label={t('onboarding.knownAs')}
          fullWidth
          value={knownAs}
          onChange={(e) => setKnownAs(e.target.value)}
          helperText={t('onboarding.knownAsHelper')}
          disabled={isLoading}
          sx={{ mb: 2 }}
        />

        <TextField
          label={t('onboarding.contactPhone')}
          fullWidth
          value={contactPhone}
          onChange={(e) => setContactPhone(e.target.value)}
          disabled={isLoading}
          sx={{ mb: 2 }}
        />

        <TextField
          label={t('onboarding.address')}
          fullWidth
          multiline
          rows={2}
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          disabled={isLoading}
          sx={{ mb: 3 }}
        />

        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            type="button"
            variant="outlined"
            onClick={handleSkip}
            disabled={isLoading}
            sx={{ flex: 1 }}
          >
            {t('onboarding.skipForNow')}
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={!displayName || isLoading}
            sx={{ flex: 1 }}
          >
            {isLoading ? <CircularProgress size={24} /> : t('onboarding.complete')}
          </Button>
        </Box>
      </Box>
    </AuthLayout>
  );
};

export default CompleteProfilePage;
```

---

## Phase 3: Support Access (W28, W29, W30)

### Files to Create

#### `features/support-access/types.ts`

```typescript
export type GrantStatus = 'active' | 'expired' | 'revoked';

export interface SuperUserGrant {
  id: string;
  grantedRole: string;
  purpose: string;
  grantedBy: string;
  grantedByName: string;
  grantedAt: string;
  expiresAt: string;
  lastActivity: string | null;
  status: GrantStatus;
  revokedAt: string | null;
}

export interface CreateGrantRequest {
  role: string;
  purpose: string;
}

export interface GrantListResponse {
  items: SuperUserGrant[];
  activeCount: number;
}
```

#### `features/support-access/api.ts`

```typescript
import { apiClient } from '@/lib/api-client';
import type { CreateGrantRequest, GrantListResponse, SuperUserGrant } from './types';

export const supportAccessApi = {
  listGrants: () =>
    apiClient.get<GrantListResponse>('/api/v1/support-access/grants').then((r) => r.data),

  createGrant: (data: CreateGrantRequest) =>
    apiClient.post<SuperUserGrant>('/api/v1/support-access/grants', data).then((r) => r.data),

  revokeGrant: (id: string) =>
    apiClient.delete(`/api/v1/support-access/grants/${id}`).then((r) => r.data),
};
```

#### `features/support-access/hooks.ts`

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supportAccessApi } from './api';
import type { CreateGrantRequest } from './types';

export function useSupportAccessGrants() {
  return useQuery({
    queryKey: ['support-access', 'grants'],
    queryFn: supportAccessApi.listGrants,
  });
}

export function useCreateGrant() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateGrantRequest) => supportAccessApi.createGrant(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['support-access'] });
    },
  });
}

export function useRevokeGrant() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => supportAccessApi.revokeGrant(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['support-access'] });
    },
  });
}
```

#### `features/support-access/components/SupportAccessSection.tsx`

This component will be added to Pod Settings page.

```typescript
import { type FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';

import { useSupportAccessGrants, useRevokeGrant } from '../hooks';
import { GrantAccessDialog } from './GrantAccessDialog';
import type { SuperUserGrant } from '../types';

export const SupportAccessSection: FC = () => {
  const { t } = useTranslation();
  const { data, isLoading } = useSupportAccessGrants();
  const revokeMutation = useRevokeGrant();
  const [dialogOpen, setDialogOpen] = useState(false);

  const activeGrants = data?.items.filter((g) => g.status === 'active') ?? [];
  const pastGrants = data?.items.filter((g) => g.status !== 'active') ?? [];

  const handleRevoke = (grant: SuperUserGrant) => {
    if (window.confirm(t('supportAccess.confirmRevoke'))) {
      revokeMutation.mutate(grant.id);
    }
  };

  return (
    <Card>
      <CardHeader
        title={t('supportAccess.title')}
        subheader={t('supportAccess.description')}
        action={
          <Button
            startIcon={<AddIcon />}
            variant="contained"
            size="small"
            onClick={() => setDialogOpen(true)}
          >
            {t('supportAccess.grantAccess')}
          </Button>
        }
      />
      <CardContent>
        <Typography variant="subtitle2" gutterBottom>
          {t('supportAccess.activeSessions')}
        </Typography>

        {activeGrants.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ py: 2 }}>
            {t('supportAccess.noActiveSessions')}
          </Typography>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('supportAccess.role')}</TableCell>
                <TableCell>{t('supportAccess.purpose')}</TableCell>
                <TableCell>{t('supportAccess.grantedAt')}</TableCell>
                <TableCell>{t('supportAccess.lastActivity')}</TableCell>
                <TableCell>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {activeGrants.map((grant) => (
                <TableRow key={grant.id}>
                  <TableCell>
                    <Chip label={grant.grantedRole} size="small" />
                  </TableCell>
                  <TableCell>{grant.purpose}</TableCell>
                  <TableCell>{new Date(grant.grantedAt).toLocaleString()}</TableCell>
                  <TableCell>
                    {grant.lastActivity
                      ? new Date(grant.lastActivity).toLocaleString()
                      : t('supportAccess.noActivity')}
                  </TableCell>
                  <TableCell>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleRevoke(grant)}
                      disabled={revokeMutation.isPending}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}

        {pastGrants.length > 0 && (
          <Box sx={{ mt: 3 }}>
            <Typography variant="subtitle2" gutterBottom>
              {t('supportAccess.history')}
            </Typography>
            {/* History table - similar structure */}
          </Box>
        )}
      </CardContent>

      <GrantAccessDialog open={dialogOpen} onClose={() => setDialogOpen(false)} />
    </Card>
  );
};
```

---

## Router Updates

Add these routes to the router configuration:

```typescript
// Bootstrap routes (super user only - no separate login page)
{ path: '/bootstrap/create-pod-chief', element: <CreatePodChiefPage />, auth: 'super_user' },

// Onboarding routes (authenticated, onboarding-specific)
{ path: '/onboarding/change-password', element: <ChangePasswordPage />, auth: 'admin', onboarding: 'pending' },
{ path: '/onboarding/complete-profile', element: <CompleteProfilePage />, auth: 'admin', onboarding: 'password_changed' },
```

### Route Guards

Update the `ProtectedRoute` component to handle:
1. **Super user check**: If `auth: 'super_user'`, verify `localStorage.getItem('isSuperUser') === 'true'`
2. **Onboarding check**: If `onboarding` is set, verify `user.onboardingStatus` matches

```typescript
// In ProtectedRoute.tsx
const ProtectedRoute: FC<{ auth: string; onboarding?: string }> = ({ auth, onboarding, children }) => {
  const { user } = useAuth();

  // Super user route
  if (auth === 'super_user') {
    const isSuperUser = localStorage.getItem('isSuperUser') === 'true';
    if (!isSuperUser) {
      return <Navigate to="/login" replace />;
    }
    return children;
  }

  // Admin route
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Onboarding status check
  if (onboarding && user.onboardingStatus !== onboarding) {
    // Redirect to appropriate onboarding step or dashboard
    if (user.onboardingStatus === 'pending') {
      return <Navigate to="/onboarding/change-password" replace />;
    }
    if (user.onboardingStatus === 'password_changed') {
      return <Navigate to="/onboarding/complete-profile" replace />;
    }
    return <Navigate to="/" replace />;
  }

  return children;
};
```

---

## i18n Keys

Add to `src/locales/en/translation.json`:

```json
{
  "bootstrap": {
    "createPodChief": "Create Pod Chief",
    "createPodChiefDescription": "Create the first Pod Chief account for this pod.",
    "displayName": "Display Name",
    "emailRequired": "Email is required",
    "emailInvalid": "Invalid email format",
    "displayNameRequired": "Display name is required",
    "createError": "Failed to create Pod Chief",
    "podChiefCreated": "Pod Chief Created Successfully",
    "temporaryPassword": "Temporary Password",
    "passwordNote": "Save this password! It will only be shown once.",
    "passwordCopied": "Password copied to clipboard",
    "emailSent": "A welcome email has been sent to the Pod Chief.",
    "goToLogin": "Go to Admin Login"
  },
  "onboarding": {
    "changePassword": "Change Password",
    "changePasswordDescription": "Please change your temporary password to continue.",
    "currentPassword": "Current Password",
    "newPassword": "New Password",
    "confirmPassword": "Confirm New Password",
    "passwordsMustMatch": "Passwords must match",
    "passwordRequirements": "Password Requirements",
    "requirements": {
      "minLength": "At least 8 characters",
      "uppercase": "At least one uppercase letter",
      "lowercase": "At least one lowercase letter",
      "number": "At least one number"
    },
    "changePasswordButton": "Change Password",
    "changePasswordError": "Failed to change password",
    "completeProfile": "Complete Your Profile",
    "completeProfileDescription": "Add optional profile information or skip to continue.",
    "displayName": "Display Name",
    "knownAs": "Known As (Nickname)",
    "knownAsHelper": "How you prefer to be addressed",
    "contactPhone": "Contact Phone",
    "address": "Address",
    "skipForNow": "Skip for Now",
    "complete": "Complete",
    "profileError": "Failed to update profile"
  },
  "supportAccess": {
    "title": "Support Access",
    "description": "Grant temporary access to super user for debugging and maintenance.",
    "grantAccess": "Grant Access",
    "activeSessions": "Active Sessions",
    "noActiveSessions": "No active support sessions",
    "role": "Role",
    "purpose": "Purpose",
    "grantedAt": "Granted At",
    "lastActivity": "Last Activity",
    "noActivity": "No activity yet",
    "history": "Session History",
    "confirmRevoke": "Are you sure you want to revoke this access?",
    "selectRole": "Select Role",
    "purposePlaceholder": "Describe the reason for this access...",
    "purposeRequired": "Purpose is required",
    "expiryNote": "Access will expire after 1 hour of inactivity or logout."
  }
}
```

---

## Tests Required

### Component Tests

- [ ] `CreatePodChiefPage.test.tsx` - Form validation, success dialog
- [ ] `ChangePasswordPage.test.tsx` - Password validation, requirements
- [ ] `CompleteProfilePage.test.tsx` - Form submission, skip functionality
- [ ] `SupportAccessSection.test.tsx` - Grant list, revoke action
- [ ] `LoginPage.test.tsx` - Add test cases for super user login routing

### Hook Tests

- [ ] `useBootstrapStatus` - Status fetching
- [ ] `useCreatePodChief` - Mutation handling
- [ ] `useChangePassword` - Error handling
- [ ] `useSupportAccessGrants` - Grant list

### Integration Tests

- [ ] Login flow routes to `/bootstrap/create-pod-chief` for super user
- [ ] Login flow routes to `/onboarding/change-password` for pending admin
- [ ] Login flow routes to `/` for active admin

---

## Definition of Done

- [ ] All acceptance criteria met
- [ ] All component tests passing
- [ ] `pnpm lint` passes
- [ ] `pnpm typecheck` passes
- [ ] i18n keys added for all user-facing text
- [ ] MUI styling (no CSS classes)
- [ ] Responsive design verified
- [ ] Manual testing of full flows
