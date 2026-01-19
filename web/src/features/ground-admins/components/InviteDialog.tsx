import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import PersonAddIcon from '@mui/icons-material/PersonAdd';

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
 * Dialog for inviting a member to become a Ground Admin
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

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <PersonAddIcon color="primary" />
        {t('groundAdmin.inviteTitle', 'Invite Ground Admin')}
      </DialogTitle>
      <DialogContent>
        <DialogContentText sx={{ mb: 2 }}>
          {t(
            'groundAdmin.inviteConfirm',
            'Are you sure you want to invite {{name}} to become a Ground Admin?',
            { name: member.name }
          )}
        </DialogContentText>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t(
            'groundAdmin.inviteDescription',
            'This will send an invitation message to the member. They can accept or decline the invitation.'
          )}
        </Typography>
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
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={isLoading}>
          {t('common.buttons.cancel', 'Cancel')}
        </Button>
        <Button
          onClick={handleConfirm}
          variant="contained"
          color="primary"
          disabled={isLoading}
        >
          {isLoading
            ? t('common.loading', 'Loading...')
            : t('groundAdmin.sendInvitation', 'Send Invitation')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
