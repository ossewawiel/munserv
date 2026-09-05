import { type FC } from 'react';
import { Trans, useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import { ConfirmDialog } from '@/components/molecules/ConfirmDialog';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';
import { formatDateTime } from '@/shared/utils/formatters';
import type { SupportGrant } from '../types';

interface RevokeGrantDialogProps {
  open: boolean;
  grant: SupportGrant | null;
  onClose: () => void;
  onConfirm: () => void;
  isLoading: boolean;
}

/**
 * Confirmation dialog shown before a pod chief revokes an active support grant.
 */
export const RevokeGrantDialog: FC<RevokeGrantDialogProps> = ({
  open,
  grant,
  onClose,
  onConfirm,
  isLoading,
}) => {
  const { t } = useTranslation();

  if (!grant) {
    return null;
  }

  const roleLabel = t(`roles.${grant.grantedRole}`, ADMIN_ROLE_LABELS[grant.grantedRole]);

  return (
    <ConfirmDialog
      open={open}
      title={t('supportAccess.revokeDialog.title', 'Revoke support access')}
      onClose={onClose}
      onConfirm={onConfirm}
      confirmLabel={t('supportAccess.revokeDialog.confirm', 'Revoke access')}
      variant="warning"
      isLoading={isLoading}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
        <Typography variant="body1">
          <Trans
            i18nKey="supportAccess.revokeDialog.body"
            defaults="Support loses access to this pod as <strong>{{role}}</strong> straight away, and any signed-in support user is logged out."
            values={{ role: roleLabel }}
            components={{ strong: <strong /> }}
          />
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary' }}>
          {t('supportAccess.purpose', 'Purpose')}: &ldquo;{grant.purpose}&rdquo;
          <br />
          {t('supportAccess.revokeDialog.grantedBy', 'Granted by {{name}} on {{date}}.', {
            name: grant.grantedByName,
            date: formatDateTime(grant.grantedAt),
          })}
        </Typography>
        <Typography variant="body2">
          {t(
            'supportAccess.revokeDialog.warning',
            'This cannot be undone. Grant support access again if it is still needed.'
          )}
        </Typography>
      </Box>
    </ConfirmDialog>
  );
};
