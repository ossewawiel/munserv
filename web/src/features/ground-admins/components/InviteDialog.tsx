import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';

import { ConfirmDialog } from '@/components/molecules/ConfirmDialog';

interface Member {
  id: string;
  name: string;
}

interface InviteDialogProps {
  open: boolean;
  member: Member | null;
  onClose: () => void;
  onConfirm: (message?: string) => void;
  isLoading?: boolean;
}

/**
 * Dialog for inviting a member to become a Ground Admin.
 * Uses the standard ConfirmDialog for consistent theming.
 */
export const InviteDialog: FC<InviteDialogProps> = ({
  open,
  member,
  onClose,
  onConfirm,
  isLoading = false,
}) => {
  const { t } = useTranslation();
  const [message, setMessage] = useState('');

  const handleConfirm = useCallback(() => {
    onConfirm(message.trim() || undefined);
    setMessage('');
  }, [onConfirm, message]);

  const handleClose = useCallback(() => {
    setMessage('');
    onClose();
  }, [onClose]);

  if (!member) return null;

  // Extract initials from name
  const nameParts = member.name.split(' ');
  const initials = nameParts.length >= 2
    ? `${nameParts[0].charAt(0)}${nameParts[nameParts.length - 1].charAt(0)}`
    : member.name.charAt(0);

  return (
    <ConfirmDialog
      open={open}
      title={t('groundAdmin.inviteTitle', 'Invite Ground Admin')}
      onClose={handleClose}
      onConfirm={handleConfirm}
      confirmLabel={t('groundAdmin.sendInvitation', 'Send Invitation')}
      cancelLabel={t('common.cancel')}
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
      <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
        {t(
          'groundAdmin.inviteConfirm',
          'Are you sure you want to invite {{name}} to become a Ground Admin?',
          { name: member.name }
        )}
      </Typography>

      {/* Description note */}
      <Typography variant="body2" color="info.main" sx={{ mb: 2 }}>
        {t(
          'groundAdmin.inviteDescription',
          'This will send an invitation message to the member. They can accept or decline the invitation.'
        )}
      </Typography>

      {/* Optional message field */}
      <TextField
        autoFocus
        multiline
        rows={3}
        fullWidth
        label={t('groundAdmin.inviteMessage', 'Optional message')}
        placeholder={t(
          'groundAdmin.inviteMessagePlaceholder',
          'Add a personal note to the invitation...'
        )}
        value={message}
        onChange={(e) => setMessage(e.target.value)}
      />
    </ConfirmDialog>
  );
};
