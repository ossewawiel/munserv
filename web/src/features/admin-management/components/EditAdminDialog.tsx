import { type FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';

import { ConfirmDialog } from '@/components/molecules/ConfirmDialog';
import type { Admin } from '../types';

interface EditAdminDialogProps {
  open: boolean;
  admin: Admin | null;
  onClose: () => void;
  onSubmit: (displayName: string) => void;
  isLoading: boolean;
}

/**
 * Dialog for editing an existing admin's display name.
 * Uses key-based reset pattern instead of useEffect to sync state.
 */
export const EditAdminDialog: FC<EditAdminDialogProps> = ({
  open,
  admin,
  onClose,
  onSubmit,
  isLoading,
}) => {
  if (!admin) return null;

  return (
    <EditAdminDialogContent
      key={admin.id}
      open={open}
      admin={admin}
      onClose={onClose}
      onSubmit={onSubmit}
      isLoading={isLoading}
    />
  );
};

interface EditAdminDialogContentProps {
  open: boolean;
  admin: Admin;
  onClose: () => void;
  onSubmit: (displayName: string) => void;
  isLoading: boolean;
}

const EditAdminDialogContent: FC<EditAdminDialogContentProps> = ({
  open,
  admin,
  onClose,
  onSubmit,
  isLoading,
}) => {
  const { t } = useTranslation();
  // Initialize state from admin prop (component remounts when admin.id changes via key)
  const [displayName, setDisplayName] = useState(admin.displayName);
  const [error, setError] = useState('');

  const validateField = (value: string): boolean => {
    if (!value.trim()) {
      setError(t('adminManagement.form.displayNameRequired', 'Display name is required'));
      return false;
    }
    setError('');
    return true;
  };

  const handleSubmit = () => {
    if (validateField(displayName)) {
      onSubmit(displayName.trim());
    }
  };

  const handleClose = () => {
    setDisplayName('');
    setError('');
    onClose();
  };

  // Extract initials from display name
  const nameParts = admin.displayName.split(' ');
  const initials =
    nameParts.length >= 2
      ? `${nameParts[0].charAt(0)}${nameParts[nameParts.length - 1].charAt(0)}`
      : admin.displayName.charAt(0);

  return (
    <ConfirmDialog
      open={open}
      title={t('adminManagement.editAdmin', 'Edit Admin')}
      onClose={handleClose}
      onConfirm={handleSubmit}
      confirmLabel={t('common.save', 'Save')}
      cancelLabel={t('common.cancel', 'Cancel')}
      isLoading={isLoading}
      size="md"
    >
      {/* Admin info */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Avatar sx={{ width: 56, height: 56, bgcolor: 'primary.main' }}>{initials}</Avatar>
        <Box>
          <Typography variant="body2" sx={{
            color: "text.secondary"
          }}>
            {admin.email}
          </Typography>
        </Box>
      </Box>

      {/* Edit form */}
      <TextField
        autoFocus
        label={t('adminManagement.form.displayName', 'Display Name')}
        fullWidth
        value={displayName}
        onChange={(e) => {
          setDisplayName(e.target.value);
          if (error) validateField(e.target.value);
        }}
        onBlur={() => validateField(displayName)}
        error={!!error}
        helperText={error}
        disabled={isLoading}
      />
    </ConfirmDialog>
  );
};
