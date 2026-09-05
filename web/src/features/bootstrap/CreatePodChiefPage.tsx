import { type FC, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';

import { AuthLayout } from '@/components/templates/AuthLayout';
import { useCreatePodChief } from './hooks';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Page for super user to create the first Pod Chief during pod bootstrap.
 *
 * Acceptance criteria (W23):
 * - Form collects: email, display name
 * - Triggers welcome email with temporary password
 * - Shows temporary password in success dialog (one-time view)
 * - Pod Chief created with PENDING onboarding status
 * - Super user redirected or shown next steps
 */
export const CreatePodChiefPage: FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const createPodChief = useCreatePodChief();

  // Form state
  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [emailError, setEmailError] = useState('');
  const [nameError, setNameError] = useState('');

  // Success state
  const [temporaryPassword, setTemporaryPassword] = useState<string | null>(null);
  const [passwordCopied, setPasswordCopied] = useState(false);

  // API error state
  const [apiError, setApiError] = useState<string | null>(null);

  // Check if user is super user
  const isSuperUser = localStorage.getItem('isSuperUser') === 'true';

  if (!isSuperUser) {
    return <Navigate to="/login" replace />;
  }

  const validateEmailField = (value: string): boolean => {
    if (!value.trim()) {
      setEmailError(t('bootstrap.emailRequired'));
      return false;
    }
    if (!EMAIL_REGEX.test(value)) {
      setEmailError(t('bootstrap.emailInvalid'));
      return false;
    }
    setEmailError('');
    return true;
  };

  const validateNameField = (value: string): boolean => {
    if (!value.trim()) {
      setNameError(t('bootstrap.displayNameRequired'));
      return false;
    }
    setNameError('');
    return true;
  };

  const handleSubmit = () => {
    setApiError(null);
    const isEmailValid = validateEmailField(email);
    const isNameValid = validateNameField(displayName);

    if (isEmailValid && isNameValid) {
      createPodChief.mutate(
        {
          email: email.trim(),
          displayName: displayName.trim(),
        },
        {
          onSuccess: (result) => {
            setTemporaryPassword(result.temporaryPassword);
          },
          onError: (error) => {
            // Handle specific error codes
            const axiosError = error as { response?: { status?: number; data?: { code?: string } } };
            if (axiosError.response?.status === 409) {
              setApiError(t('bootstrap.emailAlreadyExists', 'Email already exists'));
            } else {
              setApiError(t('bootstrap.createError'));
            }
          },
        }
      );
    }
  };

  const handleCopyPassword = async () => {
    if (temporaryPassword) {
      await navigator.clipboard.writeText(temporaryPassword);
      setPasswordCopied(true);
    }
  };

  const handleGoToLogin = () => {
    // Clear super user session
    localStorage.removeItem('isSuperUser');
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('admin');
    navigate('/login', { replace: true });
  };

  const handleDialogClose = () => {
    // Don't allow closing without going to login
    handleGoToLogin();
  };

  // Show success dialog with temporary password
  if (temporaryPassword) {
    return (
      <Dialog open onClose={handleDialogClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: 'success.main', color: 'common.white' }}>
          <Typography variant="h6" component="span" sx={{
            fontWeight: 600
          }}>
            {t('bootstrap.podChiefCreated')}
          </Typography>
        </DialogTitle>
        <DialogContent sx={{ pt: 3 }}>
          <Alert severity="warning" sx={{ mb: 2 }}>
            {t('bootstrap.passwordNote')}
          </Alert>
          <Typography variant="body2" sx={{ mb: 2 }}>
            {t('bootstrap.emailSent')}
          </Typography>
          <Typography variant="subtitle2" gutterBottom>
            {t('bootstrap.temporaryPassword')}
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
            <Typography variant="caption" sx={{
              color: "success.main"
            }}>
              {t('bootstrap.passwordCopied')}
            </Typography>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button variant="contained" onClick={handleGoToLogin}>
            {t('bootstrap.goToLogin')}
          </Button>
        </DialogActions>
      </Dialog>
    );
  }

  return (
    <AuthLayout
      header={t('bootstrap.createPodChief')}
      subtitle={t('bootstrap.createPodChiefDescription')}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {apiError && (
          <Alert severity="error" onClose={() => setApiError(null)}>
            {apiError}
          </Alert>
        )}

        <TextField
          autoFocus
          label={t('auth.email')}
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
          disabled={createPodChief.isPending}
        />

        <TextField
          label={t('bootstrap.displayName')}
          fullWidth
          value={displayName}
          onChange={(e) => {
            setDisplayName(e.target.value);
            if (nameError) validateNameField(e.target.value);
          }}
          onBlur={() => validateNameField(displayName)}
          error={!!nameError}
          helperText={nameError}
          disabled={createPodChief.isPending}
        />

        <Button
          variant="contained"
          size="large"
          fullWidth
          onClick={handleSubmit}
          disabled={createPodChief.isPending}
          startIcon={createPodChief.isPending ? <CircularProgress size={16} color="inherit" /> : undefined}
          sx={{ mt: 1 }}
        >
          {createPodChief.isPending ? t('common.loading') : t('bootstrap.createPodChief')}
        </Button>
      </Box>
    </AuthLayout>
  );
};

export default CreatePodChiefPage;
