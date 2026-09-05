import { type FC, useState, useCallback, useMemo, type SyntheticEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { AxiosError } from 'axios';
import Alert from '@mui/material/Alert';
import AlertTitle from '@mui/material/AlertTitle';
import Badge from '@mui/material/Badge';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
import Typography from '@mui/material/Typography';
import AddIcon from '@mui/icons-material/Add';
import ShieldOutlinedIcon from '@mui/icons-material/ShieldOutlined';

import { MainCard } from '@/components/atoms/MainCard';
import { Spinner } from '@/components/atoms/Spinner';
import { ErrorState } from '@/components/molecules/ErrorState';
import { EmptyState } from '@/components/molecules/EmptyState';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';
import { formatDateTime } from '@/shared/utils/formatters';
import { useSupportGrants, useGrantSupportAccess, useRevokeSupportGrant } from './hooks';
import { GrantAccessDialog } from './components/GrantAccessDialog';
import { RevokeGrantDialog } from './components/RevokeGrantDialog';
import { SupportGrantsTable } from './components/SupportGrantsTable';
import type { GrantSupportAccessRequest, SupportGrant } from './types';

interface SupportAccessErrorBody {
  code?: string;
  message?: string;
}

type SupportGrantsTab = 'active' | 'history';

/**
 * Pod Settings section that lets a pod chief grant the super user temporary
 * support access, and shows the details of the currently active grant, if any.
 */
export const SupportAccessSection: FC = () => {
  const { t } = useTranslation();
  const { data, isLoading, isError, refetch } = useSupportGrants();
  const grantMutation = useGrantSupportAccess();
  const revokeMutation = useRevokeSupportGrant();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [tab, setTab] = useState<SupportGrantsTab>('active');
  const [grantToRevoke, setGrantToRevoke] = useState<SupportGrant | null>(null);

  const activeGrants = useMemo(
    () => data?.items.filter((grant) => grant.status === 'active') ?? [],
    [data]
  );
  const historyGrants = useMemo(
    () => data?.items.filter((grant) => grant.status !== 'active') ?? [],
    [data]
  );
  const activeGrant = activeGrants[0];

  const errorCode =
    grantMutation.error instanceof AxiosError
      ? (grantMutation.error.response?.data as SupportAccessErrorBody | undefined)?.code
      : undefined;

  const revokeErrorCode =
    revokeMutation.error instanceof AxiosError
      ? (revokeMutation.error.response?.data as SupportAccessErrorBody | undefined)?.code
      : undefined;

  const handleOpenDialog = useCallback(() => {
    grantMutation.reset();
    setDialogOpen(true);
  }, [grantMutation]);

  const handleCloseDialog = useCallback(() => {
    setDialogOpen(false);
  }, []);

  const handleSubmit = useCallback(
    (request: GrantSupportAccessRequest) => {
      grantMutation.mutate(request, {
        onSuccess: () => setDialogOpen(false),
      });
    },
    [grantMutation]
  );

  const handleTabChange = useCallback((_event: SyntheticEvent, newTab: SupportGrantsTab) => {
    setTab(newTab);
  }, []);

  const handleRequestRevoke = useCallback((grant: SupportGrant) => {
    revokeMutation.reset();
    setGrantToRevoke(grant);
  }, [revokeMutation]);

  const handleCloseRevokeDialog = useCallback(() => {
    setGrantToRevoke(null);
  }, []);

  const handleConfirmRevoke = useCallback(() => {
    if (!grantToRevoke) return;
    revokeMutation.mutate(grantToRevoke.id, {
      onSuccess: () => setGrantToRevoke(null),
    });
  }, [grantToRevoke, revokeMutation]);

  return (
    <MainCard
      title={t('supportAccess.title', 'Support access')}
      secondary={
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
          disabled={!!activeGrant}
        >
          {t('supportAccess.grantButton', 'Grant support access')}
        </Button>
      }
    >
      {isLoading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <Spinner />
        </Box>
      )}

      {isError && (
        <ErrorState
          description={t('supportAccess.errors.loadFailed', 'Failed to load support access')}
          onRetry={() => refetch()}
        />
      )}

      {!isLoading && !isError && activeGrant && (
        <Alert severity="warning">
          <AlertTitle>{t('supportAccess.activeGrant', 'Support access is active')}</AlertTitle>
          <Stack spacing={0.5}>
            <Typography variant="body2">
              <strong>{t(`roles.${activeGrant.grantedRole}`, ADMIN_ROLE_LABELS[activeGrant.grantedRole])}</strong>
              {' · '}
              {t('supportAccess.grantedBy', 'Granted by')} {activeGrant.grantedByName}{' '}
              {t('supportAccess.grantedOn', 'on {{date}}', {
                date: formatDateTime(activeGrant.grantedAt),
              })}
            </Typography>
            <Typography variant="body2">
              {t('supportAccess.purpose', 'Purpose')}: &ldquo;{activeGrant.purpose}&rdquo;
            </Typography>
            <Typography variant="body2">
              {t('supportAccess.expiresAt', 'Expires')}{' '}
              {t(
                'supportAccess.expiresUntilIdle',
                '{{date}}, or one hour after the last activity, whichever comes first.',
                { date: formatDateTime(activeGrant.expiresAt) }
              )}
            </Typography>
          </Stack>
        </Alert>
      )}

      {!isLoading && !isError && data?.items.length === 0 && (
        <EmptyState
          title={t('supportAccess.emptyTitle', 'No support grants yet')}
          icon={<ShieldOutlinedIcon sx={{ fontSize: 48 }} />}
          description={t(
            'supportAccess.emptyDescription',
            'When you grant support access, the grant appears here with its role, purpose and expiry until it is revoked or expires.'
          )}
        />
      )}

      {!isLoading && !isError && (data?.items.length ?? 0) > 0 && (
        <Box sx={{ mt: 3 }}>
          {revokeErrorCode === 'grant_not_active' && (
            <Alert severity="warning" sx={{ mb: 2 }}>
              {t(
                'supportAccess.errors.grantNotActive',
                'This grant is no longer active. Reload to see its current status.'
              )}
            </Alert>
          )}

          {revokeMutation.isError && revokeErrorCode !== 'grant_not_active' && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {t('supportAccess.errors.revokeFailed', 'Failed to revoke support access')}
            </Alert>
          )}
          <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
            <Tabs
              value={tab}
              onChange={handleTabChange}
              aria-label={t('supportAccess.tabsLabel', 'Support grants')}
            >
              <Tab
                value="active"
                label={
                  <Badge
                    badgeContent={activeGrants.length}
                    color="primary"
                    sx={{ '& .MuiBadge-badge': { right: -16, top: 2 } }}
                  >
                    {t('supportAccess.tabs.active', 'Active')}
                  </Badge>
                }
              />
              <Tab
                value="history"
                label={
                  <Badge
                    badgeContent={historyGrants.length}
                    color="primary"
                    sx={{ '& .MuiBadge-badge': { right: -16, top: 2 } }}
                  >
                    {t('supportAccess.tabs.history', 'History')}
                  </Badge>
                }
              />
            </Tabs>
          </Box>

          {tab === 'active' ? (
            <SupportGrantsTable
              variant="active"
              grants={activeGrants}
              onRevoke={handleRequestRevoke}
            />
          ) : (
            <SupportGrantsTable variant="history" grants={historyGrants} />
          )}
        </Box>
      )}

      {dialogOpen && (
        <GrantAccessDialog
          open
          onClose={handleCloseDialog}
          onSubmit={handleSubmit}
          isLoading={grantMutation.isPending}
          errorCode={errorCode}
        />
      )}

      <RevokeGrantDialog
        open={!!grantToRevoke}
        grant={grantToRevoke}
        onClose={handleCloseRevokeDialog}
        onConfirm={handleConfirmRevoke}
        isLoading={revokeMutation.isPending}
      />
    </MainCard>
  );
};
