import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Divider from '@mui/material/Divider';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import PersonIcon from '@mui/icons-material/Person';
import SpeedIcon from '@mui/icons-material/Speed';
import AssignmentIcon from '@mui/icons-material/Assignment';
import WarningIcon from '@mui/icons-material/Warning';

import type { GroundAdmin } from '@/shared/types/groundAdmin';

interface RevokeDialogProps {
  open: boolean;
  groundAdmin: GroundAdmin | null;
  onClose: () => void;
  onRevoke: (reason: string) => void;
  onPutOnHold: () => void;
  isLoading?: boolean;
}

/**
 * Dialog for revoking or putting on hold Ground Admin status
 */
export const RevokeDialog: FC<RevokeDialogProps> = ({
  open,
  groundAdmin,
  onClose,
  onRevoke,
  onPutOnHold,
  isLoading = false,
}) => {
  const { t } = useTranslation();
  const [isRevokeMode, setIsRevokeMode] = useState(false);
  const [revokeReason, setRevokeReason] = useState('');

  const handlePutOnHold = useCallback(() => {
    onPutOnHold();
  }, [onPutOnHold]);

  const handleRevokeClick = useCallback(() => {
    setIsRevokeMode(true);
  }, []);

  const handleRevokeConfirm = useCallback(() => {
    if (revokeReason.trim()) {
      onRevoke(revokeReason.trim());
      setRevokeReason('');
      setIsRevokeMode(false);
    }
  }, [onRevoke, revokeReason]);

  const handleClose = useCallback(() => {
    setIsRevokeMode(false);
    setRevokeReason('');
    onClose();
  }, [onClose]);

  if (!groundAdmin) return null;

  const responseRateColor =
    groundAdmin.responseRate >= 80
      ? 'success'
      : groundAdmin.responseRate >= 50
        ? 'warning'
        : 'error';

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        {isRevokeMode
          ? t('groundAdmin.revokeTitle', 'Revoke Ground Admin Status')
          : t('groundAdmin.manageTitle', 'Manage Ground Admin')}
      </DialogTitle>
      <DialogContent>
        {!isRevokeMode ? (
          <>
            {/* Ground Admin Info */}
            <Box sx={{ mb: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                <PersonIcon color="action" fontSize="small" />
                <Typography variant="subtitle1" sx={{
                  fontWeight: 600
                }}>
                  {groundAdmin.name}
                </Typography>
                <Chip
                  label={t(`groundAdmin.status.${groundAdmin.status}`, groundAdmin.status)}
                  size="small"
                  color={groundAdmin.status === 'active' ? 'success' : 'warning'}
                />
              </Box>

              {/* Stats */}
              <Box
                sx={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: 2,
                  p: 2,
                  bgcolor: 'background.default',
                  borderRadius: 1,
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <SpeedIcon color="action" fontSize="small" />
                  <Box>
                    <Typography variant="caption" sx={{
                      color: "text.secondary"
                    }}>
                      {t('groundAdmin.responseRate', 'Response Rate')}
                    </Typography>
                    <Typography
                      variant="body2"
                      color={`${responseRateColor}.main`}
                      sx={{
                        fontWeight: 600
                      }}
                    >
                      {groundAdmin.responseRate}%
                    </Typography>
                  </Box>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <AssignmentIcon color="action" fontSize="small" />
                  <Box>
                    <Typography variant="caption" sx={{
                      color: "text.secondary"
                    }}>
                      {t('groundAdmin.pendingVerifications', 'Pending')}
                    </Typography>
                    <Typography variant="body2" sx={{
                      fontWeight: 600
                    }}>
                      {groundAdmin.pendingVerifications}
                    </Typography>
                  </Box>
                </Box>
              </Box>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, mb: 2 }}>
              <WarningIcon color="warning" fontSize="small" sx={{ mt: 0.5 }} />
              <Typography variant="body2" sx={{
                color: "text.secondary"
              }}>
                {t(
                  'groundAdmin.manageDescription',
                  'You can temporarily put this Ground Admin on hold if they need a break, or revoke their status completely if needed.'
                )}
              </Typography>
            </Box>
          </>
        ) : (
          <>
            <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, mb: 2 }}>
              <WarningIcon color="error" fontSize="small" sx={{ mt: 0.5 }} />
              <Typography variant="body2" sx={{
                color: "error.main"
              }}>
                {t(
                  'groundAdmin.revokeWarning',
                  'This action cannot be undone. The member will be notified and will lose their Ground Admin privileges.'
                )}
              </Typography>
            </Box>
            <TextField
              autoFocus
              multiline
              rows={3}
              fullWidth
              required
              label={t('groundAdmin.revokeReason', 'Reason for revocation')}
              value={revokeReason}
              onChange={(e) => setRevokeReason(e.target.value)}
              error={!revokeReason.trim() && revokeReason.length > 0}
              helperText={
                !revokeReason.trim() && revokeReason.length > 0
                  ? t('common.validation.required', 'This field is required')
                  : ''
              }
            />
          </>
        )}
      </DialogContent>
      <DialogActions>
        {!isRevokeMode ? (
          <>
            <Button onClick={handleClose} disabled={isLoading}>
              {t('common.buttons.cancel', 'Cancel')}
            </Button>
            {groundAdmin.status === 'active' && (
              <Button onClick={handlePutOnHold} color="warning" disabled={isLoading}>
                {t('groundAdmin.putOnHold', 'Put on Hold')}
              </Button>
            )}
            <Button
              onClick={handleRevokeClick}
              variant="contained"
              color="error"
              disabled={isLoading}
            >
              {t('groundAdmin.revoke', 'Revoke Status')}
            </Button>
          </>
        ) : (
          <>
            <Button onClick={() => setIsRevokeMode(false)} disabled={isLoading}>
              {t('common.buttons.back', 'Back')}
            </Button>
            <Button
              onClick={handleRevokeConfirm}
              variant="contained"
              color="error"
              disabled={isLoading || !revokeReason.trim()}
            >
              {isLoading
                ? t('common.loading', 'Loading...')
                : t('common.buttons.confirm', 'Confirm Revoke')}
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  );
};
