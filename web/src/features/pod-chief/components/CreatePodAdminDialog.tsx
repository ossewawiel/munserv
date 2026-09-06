import { type FC, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AxiosError } from 'axios';
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

import { ADMIN_ROLE_LABELS, getManageableRoles, getRoleLevel, type AdminRole } from '@/shared/types/admin';
import { usePodSetup } from '@/shared/hooks/usePodSetup';
import type { CreatePodAdministratorRequest } from '../types';

interface CreatePodAdminDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: CreatePodAdministratorRequest) => void;
  isLoading: boolean;
  temporaryPassword?: string;
  /** The most recent failure from the create-administrator mutation, if any. */
  error?: unknown;
}

interface CreateAdministratorErrorBody {
  error?: {
    code?: string;
    message?: string;
  };
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
  error,
}) => {
  const { t } = useTranslation();
  const { status: podSetupStatus } = usePodSetup();
  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [role, setRole] = useState<AdminRole>('pod_admin');
  const [wardId, setWardId] = useState('');
  const [sectorId, setSectorId] = useState('');
  const [emailError, setEmailError] = useState('');
  const [nameError, setNameError] = useState('');
  const [wardError, setWardError] = useState('');
  const [sectorError, setSectorError] = useState('');
  const [passwordCopied, setPasswordCopied] = useState(false);
  const [emailDirtySinceError, setEmailDirtySinceError] = useState(false);

  const httpStatus = error instanceof AxiosError ? error.response?.status : undefined;
  const serverErrorBody =
    error instanceof AxiosError
      ? (error.response?.data as CreateAdministratorErrorBody | undefined)?.error
      : undefined;

  const isDuplicateEmail = httpStatus === 409 && !emailDirtySinceError;
  const duplicateEmailError = isDuplicateEmail
    ? t('podAdministrators.errors.emailExists')
    : '';

  const formError = useMemo(() => {
    if (!httpStatus || httpStatus === 409) return '';
    if (httpStatus >= 500) return t('podAdministrators.errors.createFailed');
    return serverErrorBody?.message ?? t('podAdministrators.errors.createFailed');
  }, [httpStatus, serverErrorBody, t]);

  // Pod Chief can manage all roles below their own
  const manageableRoles = getManageableRoles('pod_chief');

  // Determine if ward/sector selection is needed based on role level
  const roleLevel = getRoleLevel(role);
  const requiresWard = roleLevel === 'ward';
  const requiresSector = roleLevel === 'sector';

  // Get available wards and sectors from pod setup
  const wards = podSetupStatus?.wards ?? [];
  const sectors = podSetupStatus?.sectors ?? [];

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

  const validateWardField = (): boolean => {
    if (requiresWard && !wardId) {
      setWardError(t('podAdministrators.form.wardRequired'));
      return false;
    }
    setWardError('');
    return true;
  };

  const validateSectorField = (): boolean => {
    if (requiresSector && !sectorId) {
      setSectorError(t('podAdministrators.form.sectorRequired'));
      return false;
    }
    setSectorError('');
    return true;
  };

  const handleSubmit = () => {
    const isEmailValid = validateEmailField(email);
    const isNameValid = validateNameField(displayName);
    const isWardValid = validateWardField();
    const isSectorValid = validateSectorField();

    if (isEmailValid && isNameValid && isWardValid && isSectorValid) {
      setEmailDirtySinceError(false);
      onSubmit({
        email: email.trim(),
        displayName: displayName.trim(),
        role,
        wardId: requiresWard ? wardId : undefined,
        sectorId: requiresSector ? sectorId : undefined,
      });
    }
  };

  const handleRoleChange = (newRole: AdminRole) => {
    setRole(newRole);
    // Clear ward/sector selection when role level changes
    const newRoleLevel = getRoleLevel(newRole);
    if (newRoleLevel !== 'ward') {
      setWardId('');
      setWardError('');
    }
    if (newRoleLevel !== 'sector') {
      setSectorId('');
      setSectorError('');
    }
  };

  const handleClose = () => {
    setEmail('');
    setDisplayName('');
    setRole('pod_admin');
    setWardId('');
    setSectorId('');
    setEmailError('');
    setNameError('');
    setWardError('');
    setSectorError('');
    setPasswordCopied(false);
    setEmailDirtySinceError(false);
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
          <Typography variant="h6" component="span" sx={{
            fontWeight: 600
          }}>
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
            <Typography variant="caption" sx={{
              color: "success.main"
            }}>
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
        <Typography variant="h6" component="span" sx={{
          fontWeight: 600
        }}>
          {t('podAdministrators.addNew')}
        </Typography>
      </DialogTitle>
      <DialogContent sx={{ pt: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          {formError && <Alert severity="error">{formError}</Alert>}
          <TextField
            autoFocus
            label={t('podAdministrators.form.email')}
            type="email"
            fullWidth
            value={email}
            onChange={(e) => {
              setEmail(e.target.value);
              setEmailDirtySinceError(true);
              if (emailError) validateEmailField(e.target.value);
            }}
            onBlur={() => validateEmailField(email)}
            error={!!emailError || isDuplicateEmail}
            helperText={emailError || duplicateEmailError}
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
              onChange={(e) => handleRoleChange(e.target.value as AdminRole)}
            >
              {manageableRoles.map((roleOption) => (
                <MenuItem key={roleOption} value={roleOption}>
                  {ADMIN_ROLE_LABELS[roleOption]}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          {/* Ward selection - shown for ward-level roles */}
          {requiresWard && (
            <FormControl fullWidth disabled={isLoading} error={!!wardError}>
              <InputLabel id="ward-select-label">{t('podAdministrators.form.selectWard')}</InputLabel>
              <Select
                labelId="ward-select-label"
                value={wardId}
                label={t('podAdministrators.form.selectWard')}
                onChange={(e) => {
                  setWardId(e.target.value);
                  if (wardError) setWardError('');
                }}
              >
                {wards.map((ward) => (
                  <MenuItem key={ward.id} value={ward.id}>
                    {ward.name}
                  </MenuItem>
                ))}
              </Select>
              {wardError && (
                <Typography variant="caption" color="error" sx={{ mt: 0.5, ml: 1.75 }}>
                  {wardError}
                </Typography>
              )}
            </FormControl>
          )}

          {/* Sector selection - shown for sector-level roles */}
          {requiresSector && (
            <FormControl fullWidth disabled={isLoading} error={!!sectorError}>
              <InputLabel id="sector-select-label">{t('podAdministrators.form.selectSector')}</InputLabel>
              <Select
                labelId="sector-select-label"
                value={sectorId}
                label={t('podAdministrators.form.selectSector')}
                onChange={(e) => {
                  setSectorId(e.target.value);
                  if (sectorError) setSectorError('');
                }}
              >
                {sectors.map((sector) => (
                  <MenuItem key={sector.id} value={sector.id}>
                    {sector.name}
                  </MenuItem>
                ))}
              </Select>
              {sectorError && (
                <Typography variant="caption" color="error" sx={{ mt: 0.5, ml: 1.75 }}>
                  {sectorError}
                </Typography>
              )}
            </FormControl>
          )}
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
