import { type FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import FormControl from '@mui/material/FormControl';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';

import { ADMIN_ROLE_LABELS, getManageableRoles, type AdminRole } from '@/shared/types/admin';
import type { CreatePodAdministratorRequest } from '../types';

interface CreatePodAdminDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: CreatePodAdministratorRequest) => void;
  isLoading: boolean;
  temporaryPassword?: string;
}

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Dialog for creating a new pod administrator.
 * Pod Chief can create admins at any level below their own (pod_admin, ward_*, sector_*).
 * Shows a form initially, then displays the temporary password on success.
 */
export const CreatePodAdminDialog: FC<CreatePodAdminDialogProps> = ({
  open,
  onClose,
  onSubmit,
  isLoading,
  temporaryPassword,
}) => {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [role, setRole] = useState<AdminRole>('pod_admin');
  const [emailError, setEmailError] = useState('');
  const [nameError, setNameError] = useState('');
  const [passwordCopied, setPasswordCopied] = useState(false);

  // Pod Chief can manage all roles below their own
  const manageableRoles = getManageableRoles('pod_chief');

  const validateEmailField = (value: string): boolean => {
    if (!value.trim()) {
      setEmailError(t('podAdministrators.form.emailRequired'));
      return false;
    }
    if (!EMAIL_REGEX.test(value)) {
      setEmailError(t('podAdministrators.form.emailInvalid'));
      return false;
    }
    setEmailError('');
    return true;
  };

  const validateNameField = (value: string): boolean => {
    if (!value.trim()) {
      setNameError(t('podAdministrators.form.displayNameRequired'));
      return false;
    }
    setNameError('');
    return true;
  };

  const handleSubmit = () => {
    const isEmailValid = validateEmailField(email);
    const isNameValid = validateNameField(displayName);

    if (isEmailValid && isNameValid) {
      onSubmit({
        email: email.trim(),
        displayName: displayName.trim(),
        role,
      });
    }
  };

  const handleClose = () => {
    setEmail('');
    setDisplayName('');
    setRole('pod_admin');
    setEmailError('');
    setNameError('');
    setPasswordCopied(false);
    onClose();
  };

  const handleCopyPassword = async () => {
    if (temporaryPassword) {
      await navigator.clipboard.writeText(temporaryPassword);
      setPasswordCopied(true);
    }
  };

  // Show password result after successful creation
  if (temporaryPassword) {
    return (
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: 'success.main', color: 'common.white' }}>
          <Typography variant="h6" component="span" fontWeight={600}>
            {t('podAdministrators.success.created')}
          </Typography>
        </DialogTitle>
        <DialogContent sx={{ pt: 3 }}>
          <Alert severity="warning" sx={{ mb: 2 }}>
            {t('podAdministrators.passwordNote')}
          </Alert>
          <Typography variant="subtitle2" gutterBottom>
            {t('podAdministrators.temporaryPassword')}
          </Typography>
          <TextField
            fullWidth
            value={temporaryPassword}
            slotProps={{
              input: {
                readOnly: true,
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={handleCopyPassword} edge="end">
                      <ContentCopyIcon />
                    </IconButton>
                  </InputAdornment>
                ),
              },
            }}
            sx={{ mb: 1 }}
          />
          {passwordCopied && (
            <Typography variant="caption" color="success.main">
              {t('podAdministrators.passwordCopied')}
            </Typography>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button variant="contained" onClick={handleClose}>
            {t('common.close')}
          </Button>
        </DialogActions>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ bgcolor: 'secondary.main', color: 'common.white' }}>
        <Typography variant="h6" component="span" fontWeight={600}>
          {t('podAdministrators.addNew')}
        </Typography>
      </DialogTitle>
      <DialogContent sx={{ pt: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <TextField
            autoFocus
            label={t('podAdministrators.form.email')}
            type="email"
            fullWidth
            value={email}
            onChange={(e) => {
              setEmail(e.target.value);
              if (emailError) validateEmailField(e.target.value);
            }}
            onBlur={() => validateEmailField(email)}
            error={!!emailError}
            helperText={emailError}
            disabled={isLoading}
          />
          <TextField
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
          <FormControl fullWidth disabled={isLoading}>
            <InputLabel id="role-select-label">{t('podAdministrators.form.role')}</InputLabel>
            <Select
              labelId="role-select-label"
              value={role}
              label={t('podAdministrators.form.role')}
              onChange={(e) => setRole(e.target.value as AdminRole)}
            >
              {manageableRoles.map((roleOption) => (
                <MenuItem key={roleOption} value={roleOption}>
                  {ADMIN_ROLE_LABELS[roleOption]}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
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
          {isLoading ? t('common.loading') : t('podAdministrators.addNew')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
