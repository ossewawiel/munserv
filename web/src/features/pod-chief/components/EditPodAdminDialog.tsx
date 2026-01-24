import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';

import type { PodAdministrator } from '../types';

interface EditPodAdminDialogProps {
  open: boolean;
  admin: PodAdministrator | null;
  onClose: () => void;
  onSubmit: (displayName: string) => void;
  isLoading: boolean;
}

/**
 * Dialog for editing a pod administrator's display name.
 * Currently only displayName is editable.
 * Uses TransitionGroup callbacks to initialize form state when dialog opens.
 */
export const EditPodAdminDialog: FC<EditPodAdminDialogProps> = ({
  open,
  admin,
  onClose,
  onSubmit,
  isLoading,
}) => {
  const { t } = useTranslation();
  // Initialize with admin's displayName if available, updated on dialog open via TransitionProps
  const [displayName, setDisplayName] = useState(admin?.displayName ?? '');
  const [nameError, setNameError] = useState('');

  // Reset form when dialog opens (via TransitionProps)
  const handleEnter = useCallback(() => {
    if (admin) {
      setDisplayName(admin.displayName);
      setNameError('');
    }
  }, [admin]);

  const validateNameField = (value: string): boolean => {
    if (!value.trim()) {
      setNameError(t('podAdministrators.form.displayNameRequired'));
      return false;
    }
    setNameError('');
    return true;
  };

  const handleSubmit = () => {
    if (validateNameField(displayName)) {
      onSubmit(displayName.trim());
    }
  };

  const handleClose = () => {
    setDisplayName('');
    setNameError('');
    onClose();
  };

  if (!admin) return null;

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      TransitionProps={{ onEnter: handleEnter }}
    >
      <DialogTitle sx={{ bgcolor: 'secondary.main', color: 'common.white' }}>
        <Typography variant="h6" component="span" fontWeight={600}>
          {t('podAdministrators.editAdmin')}
        </Typography>
      </DialogTitle>
      <DialogContent sx={{ pt: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <TextField
            label={t('podAdministrators.form.email')}
            fullWidth
            value={admin.email}
            disabled
            helperText={t('podAdministrators.form.emailReadonly')}
          />
          <TextField
            autoFocus
            label={t('podAdministrators.form.displayName')}
            fullWidth
            value={displayName}
            onChange={(e) => {
              setDisplayName(e.target.value);
              if (nameError) validateNameField(e.target.value);
            }}
            onBlur={() => validateNameField(displayName)}
            error={!!nameError}
            helperText={nameError}
            disabled={isLoading}
          />
        </Box>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2, gap: 1 }}>
        <Button variant="outlined" color="secondary" onClick={handleClose} disabled={isLoading}>
          {t('common.cancel')}
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={isLoading}
          startIcon={isLoading ? <CircularProgress size={16} color="inherit" /> : undefined}
        >
          {isLoading ? t('common.loading') : t('common.save')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
