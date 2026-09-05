import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';

import { ConfirmDialog } from '@/components/molecules/ConfirmDialog';

interface RevokeInviteDialogProps {
  open: boolean;
  member: { id: string; name: string } | null;
  onClose: () => void;
  onConfirm: () => void;
  isLoading: boolean;
}

/**
 * Confirmation dialog for revoking a pending Ground Admin invitation.
 * Uses the standard ConfirmDialog for consistent theming.
 */
export const RevokeInviteDialog: FC<RevokeInviteDialogProps> = ({
  open,
  member,
  onClose,
  onConfirm,
  isLoading,
}) => {
  const { t } = useTranslation();

  if (!member) return null;

  // Extract initials from name
  const nameParts = member.name.split(' ');
  const initials = nameParts.length >= 2
    ? `${nameParts[0].charAt(0)}${nameParts[nameParts.length - 1].charAt(0)}`
    : member.name.charAt(0);

  return (
    <ConfirmDialog
      open={open}
      title={t('members.revokeInvite')}
      onClose={onClose}
      onConfirm={onConfirm}
      confirmLabel={t('members.revokeInvite')}
      cancelLabel={t('common.cancel')}
      variant="warning"
      isLoading={isLoading}
      size="md"
    >
      {/* Member info */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
        <Avatar sx={{ width: 56, height: 56, bgcolor: 'primary.main' }}>
          {initials}
        </Avatar>
        <Box>
          <Typography variant="h6">{member.name}</Typography>
        </Box>
      </Box>

      {/* Confirmation message */}
      <Typography variant="body1" sx={{
        color: "text.secondary"
      }}>
        {t('members.revokeInviteConfirm', { name: member.name })}
      </Typography>

      {/* Warning note */}
      <Typography
        variant="body2"
        sx={{
          color: "warning.main",
          mt: 2
        }}>
        {t('members.revokeInviteWarning', 'This action cannot be undone. You can send a new invitation later.')}
      </Typography>
    </ConfirmDialog>
  );
};
