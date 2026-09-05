import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';

import { ConfirmDialog } from '@/components/molecules/ConfirmDialog';
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
  const confirmLabel = isApprove
    ? t('members.approve')
    : t('members.reject');

  return (
    <ConfirmDialog
      open={open}
      title={title}
      onClose={onCancel}
      onConfirm={onConfirm}
      confirmLabel={confirmLabel}
      cancelLabel={t('common.cancel')}
      variant={isApprove ? 'default' : 'warning'}
      isLoading={isLoading}
      size="md"
    >
      {/* Member info */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
        <Avatar sx={{ width: 56, height: 56, bgcolor: 'primary.main' }}>
          {member.firstName.charAt(0)}
          {member.surname.charAt(0)}
        </Avatar>
        <Box>
          <Typography variant="h6">
            {member.firstName} {member.surname}
          </Typography>
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {member.email}
          </Typography>
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {member.phoneNumber}
          </Typography>
        </Box>
      </Box>

      {/* Confirmation message */}
      <Typography variant="body1" sx={{
        color: "text.secondary"
      }}>
        {isApprove
          ? t('members.approveConfirmation')
          : t('members.rejectConfirmation')}
      </Typography>

      {/* Additional notes */}
      {isApprove && (
        <Typography
          variant="body2"
          sx={{
            color: "info.main",
            mt: 2
          }}>
          {t('members.approveEmailNote')}
        </Typography>
      )}

      {!isApprove && (
        <Typography
          variant="body2"
          sx={{
            color: "warning.main",
            mt: 2
          }}>
          {t('members.rejectWarning')}
        </Typography>
      )}
    </ConfirmDialog>
  );
};
