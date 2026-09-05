import { type FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import FormControl from '@mui/material/FormControl';
import FormHelperText from '@mui/material/FormHelperText';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';

import { ADMIN_ROLE_LABELS, getManageableRoles, type AdminRole } from '@/shared/types/admin';
import type { GrantSupportAccessRequest } from '../types';

const PURPOSE_MIN_LENGTH = 10;
const PURPOSE_MAX_LENGTH = 500;

interface GrantAccessDialogProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (request: GrantSupportAccessRequest) => void;
  isLoading: boolean;
  errorCode?: string;
}

/**
 * Dialog for the pod chief to grant the super user temporary support access.
 */
export const GrantAccessDialog: FC<GrantAccessDialogProps> = ({
  open,
  onClose,
  onSubmit,
  isLoading,
  errorCode,
}) => {
  const { t } = useTranslation();
  const manageableRoles = getManageableRoles('pod_chief');
  const [grantedRole, setGrantedRole] = useState<AdminRole>(manageableRoles[0]);
  const [purpose, setPurpose] = useState('');
  const [purposeError, setPurposeError] = useState('');

  const validatePurpose = (value: string): boolean => {
    const trimmed = value.trim();
    if (!trimmed) {
      setPurposeError(t('supportAccess.errors.purposeRequired', 'Purpose is required'));
      return false;
    }
    if (trimmed.length < PURPOSE_MIN_LENGTH) {
      setPurposeError(
        t('supportAccess.errors.purposeTooShort', 'Purpose must be at least 10 characters')
      );
      return false;
    }
    if (trimmed.length > PURPOSE_MAX_LENGTH) {
      setPurposeError(
        t('supportAccess.errors.purposeTooLong', 'Purpose must be 500 characters or fewer')
      );
      return false;
    }
    setPurposeError('');
    return true;
  };

  const handleClose = () => {
    setGrantedRole(manageableRoles[0]);
    setPurpose('');
    setPurposeError('');
    onClose();
  };

  const handleSubmit = () => {
    if (validatePurpose(purpose)) {
      onSubmit({ grantedRole, purpose: purpose.trim() });
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ bgcolor: 'secondary.main', color: 'common.white' }}>
        <Typography variant="h6" component="span" sx={{ fontWeight: 600 }}>
          {t('supportAccess.dialog.title', 'Grant support access')}
        </Typography>
      </DialogTitle>
      <DialogContent sx={{ pt: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          {errorCode === 'active_grant_exists' && (
            <Alert severity="warning">
              {t(
                'supportAccess.errors.activeGrantExists',
                'This pod already has an active support grant. Revoke it before granting another.'
              )}
            </Alert>
          )}

          <Alert severity="info">
            {t(
              'supportAccess.dialog.expiryNotice',
              'The grant ends when support signs out, and after one hour without activity. You can revoke it at any time.'
            )}
          </Alert>

          <FormControl fullWidth disabled={isLoading}>
            <InputLabel id="grant-access-role-label">
              {t('supportAccess.dialog.roleLabel', 'Role to grant')}
            </InputLabel>
            <Select
              labelId="grant-access-role-label"
              label={t('supportAccess.dialog.roleLabel', 'Role to grant')}
              value={grantedRole}
              onChange={(e) => setGrantedRole(e.target.value as AdminRole)}
            >
              {manageableRoles.map((role) => (
                <MenuItem key={role} value={role}>
                  {t(`roles.${role}`, ADMIN_ROLE_LABELS[role])}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <Box>
            <TextField
              label={t('supportAccess.dialog.purposeLabel', 'Purpose')}
              fullWidth
              multiline
              minRows={4}
              value={purpose}
              onChange={(e) => {
                setPurpose(e.target.value);
                if (purposeError) validatePurpose(e.target.value);
              }}
              onBlur={() => validatePurpose(purpose)}
              error={!!purposeError}
              disabled={isLoading}
              slotProps={{
                htmlInput: { maxLength: PURPOSE_MAX_LENGTH },
              }}
            />
            <Box
              sx={{
                display: 'flex',
                justifyContent: 'space-between',
                gap: 2,
                mt: 0.5,
                px: 1.75,
              }}
            >
              <FormHelperText error={!!purposeError} sx={{ m: 0 }}>
                {purposeError ||
                  t(
                    'supportAccess.dialog.purposeHelp',
                    'Say what support is being asked to do. Between 10 and 500 characters.'
                  )}
              </FormHelperText>
              <Typography variant="caption" sx={{ color: 'text.secondary', whiteSpace: 'nowrap' }}>
                {purpose.length} / {PURPOSE_MAX_LENGTH}
              </Typography>
            </Box>
          </Box>
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
            : t('supportAccess.dialog.submit', 'Grant access')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
