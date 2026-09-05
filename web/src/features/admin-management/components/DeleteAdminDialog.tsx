import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';

import { ConfirmDialog } from '@/components/molecules/ConfirmDialog';
import type { Admin } from '../types';

interface DeleteAdminDialogProps {
  open: boolean;
  admin: Admin | null;
  onClose: () => void;
  onConfirm: () => void;
  isLoading: boolean;
}

/**
 * Confirmation dialog for deleting (soft delete) an admin.
 */
export const DeleteAdminDialog: FC<DeleteAdminDialogProps> = ({
  open,
  admin,
  onClose,
  onConfirm,
  isLoading,
}) => {
  const { t } = useTranslation();

  if (!admin) return null;

  // Extract initials from display name
  const nameParts = admin.displayName.split(' ');
  const initials =
    nameParts.length >= 2
      ? `${nameParts[0].charAt(0)}${nameParts[nameParts.length - 1].charAt(0)}`
      : admin.displayName.charAt(0);

  return (
    <ConfirmDialog
      open={open}
      title={t('adminManagement.deleteAdmin', 'Delete Admin')}
      onClose={onClose}
      onConfirm={onConfirm}
      confirmLabel={t('common.delete', 'Delete')}
      cancelLabel={t('common.cancel', 'Cancel')}
      variant="warning"
      isLoading={isLoading}
      size="md"
    >
      {/* Admin info */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
        <Avatar sx={{ width: 56, height: 56, bgcolor: 'error.main' }}>{initials}</Avatar>
        <Box>
          <Typography variant="h6">{admin.displayName}</Typography>
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {admin.email}
          </Typography>
        </Box>
      </Box>

      {/* Confirmation message */}
      <Typography
        variant="body1"
        sx={{
          color: "text.secondary",
          mb: 2
        }}>
        {t(
          'adminManagement.confirmDelete',
          'Are you sure you want to delete this admin?'
        )}
      </Typography>

      {/* Warning */}
      <Alert severity="warning">
        {t(
          'adminManagement.deleteWarning',
          'This action cannot be undone.'
        )}
      </Alert>
    </ConfirmDialog>
  );
};
