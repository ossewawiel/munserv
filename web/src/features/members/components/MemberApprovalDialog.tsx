import { type FC } from 'react';
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
import type { MemberListItem } from '../types';

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
  const title = isApprove
    ? t('members.approveTitle')
    : t('members.rejectTitle');
  const confirmText = isApprove
    ? t('members.approve')
    : t('members.reject');

  return (
    <Dialog open={open} onClose={onCancel} maxWidth="sm" fullWidth>
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
          variant={isApprove ? 'primary' : 'danger'}
          isLoading={isLoading}
        >
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
