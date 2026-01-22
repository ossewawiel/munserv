import { type FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';

interface CreateAdminDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: { email: string; displayName: string }) => void;
  isLoading: boolean;
  temporaryPassword?: string;
}

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Dialog for creating a new sector admin.
 * Shows a form initially, then displays the temporary password on success.
 */
export const CreateAdminDialog: FC<CreateAdminDialogProps> = ({
  open,
  onClose,
  onSubmit,
  isLoading,
  temporaryPassword,
}) => {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [emailError, setEmailError] = useState('');
  const [nameError, setNameError] = useState('');
  const [passwordCopied, setPasswordCopied] = useState(false);

  const validateEmailField = (value: string): boolean => {
    if (!value.trim()) {
      setEmailError(t('adminManagement.form.emailRequired', 'Email is required'));
      return false;
    }
    if (!EMAIL_REGEX.test(value)) {
      setEmailError(t('adminManagement.form.emailInvalid', 'Invalid email format'));
      return false;
    }
    setEmailError('');
    return true;
  };

  const validateNameField = (value: string): boolean => {
    if (!value.trim()) {
      setNameError(t('adminManagement.form.displayNameRequired', 'Display name is required'));
      return false;
    }
    setNameError('');
    return true;
  };

  const handleSubmit = () => {
    const isEmailValid = validateEmailField(email);
    const isNameValid = validateNameField(displayName);

    if (isEmailValid && isNameValid) {
      onSubmit({ email: email.trim(), displayName: displayName.trim() });
    }
  };

  const handleClose = () => {
    setEmail('');
    setDisplayName('');
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
            {t('adminManagement.success.created', 'Admin created successfully')}
          </Typography>
        </DialogTitle>
        <DialogContent sx={{ pt: 3 }}>
          <Alert severity="warning" sx={{ mb: 2 }}>
            {t(
              'adminManagement.passwordNote',
              'Save this password - it will only be shown once'
            )}
          </Alert>
          <Typography variant="subtitle2" gutterBottom>
            {t('adminManagement.temporaryPassword', 'Temporary Password')}
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
              {t('adminManagement.passwordCopied', 'Password copied to clipboard')}
            </Typography>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button variant="contained" onClick={handleClose}>
            {t('common.close', 'Close')}
          </Button>
        </DialogActions>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ bgcolor: 'secondary.main', color: 'common.white' }}>
        <Typography variant="h6" component="span" fontWeight={600}>
          {t('adminManagement.createAdmin', 'Create Admin')}
        </Typography>
      </DialogTitle>
      <DialogContent sx={{ pt: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <TextField
            autoFocus
            label={t('adminManagement.form.email', 'Email Address')}
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
            label={t('adminManagement.form.displayName', 'Display Name')}
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
          {t('common.cancel', 'Cancel')}
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={isLoading}
          startIcon={isLoading ? <CircularProgress size={16} color="inherit" /> : undefined}
        >
          {isLoading
            ? t('common.loading', 'Loading...')
            : t('adminManagement.createAdmin', 'Create Admin')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
