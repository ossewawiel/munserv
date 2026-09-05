import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { AxiosError } from 'axios';
import Alert from '@mui/material/Alert';
import AlertTitle from '@mui/material/AlertTitle';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import AddIcon from '@mui/icons-material/Add';
import ShieldOutlinedIcon from '@mui/icons-material/ShieldOutlined';

import { MainCard } from '@/components/atoms/MainCard';
import { Spinner } from '@/components/atoms/Spinner';
import { ErrorState } from '@/components/molecules/ErrorState';
import { EmptyState } from '@/components/molecules/EmptyState';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';
import { formatDateTime } from '@/shared/utils/formatters';
import { useSupportGrants, useGrantSupportAccess } from './hooks';
import { GrantAccessDialog } from './components/GrantAccessDialog';
import type { GrantSupportAccessRequest } from './types';

interface SupportAccessErrorBody {
  code?: string;
  message?: string;
}

/**
 * Pod Settings section that lets a pod chief grant the super user temporary
 * support access, and shows the details of the currently active grant, if any.
 */
export const SupportAccessSection: FC = () => {
  const { t } = useTranslation();
  const { data, isLoading, isError, refetch } = useSupportGrants('active');
  const grantMutation = useGrantSupportAccess();
  const [dialogOpen, setDialogOpen] = useState(false);

  const activeGrant = data?.items[0];

  const errorCode =
    grantMutation.error instanceof AxiosError
      ? (grantMutation.error.response?.data as SupportAccessErrorBody | undefined)?.code
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

      {!isLoading && !isError && !activeGrant && (
        <EmptyState
          title={t('supportAccess.emptyTitle', 'No support grants yet')}
          icon={<ShieldOutlinedIcon sx={{ fontSize: 48 }} />}
          description={t(
            'supportAccess.emptyDescription',
            'When you grant support access, the grant appears here with its role, purpose and expiry until it is revoked or expires.'
          )}
        />
      )}

      <GrantAccessDialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmit}
        isLoading={grantMutation.isPending}
        errorCode={errorCode}
      />
    </MainCard>
  );
};
