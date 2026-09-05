import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Divider from '@mui/material/Divider';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import PersonIcon from '@mui/icons-material/Person';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';

import type { GroundAdminApplication } from '@/shared/types/groundAdmin';
import { formatDate } from '@/shared/utils/formatters';

interface ApproveDialogProps {
  open: boolean;
  application: GroundAdminApplication | null;
  onClose: () => void;
  onApprove: () => void;
  onDecline: (reason: string) => void;
  isLoading?: boolean;
}

/**
 * Dialog for approving or declining Ground Admin applications
 */
export const ApproveDialog: FC<ApproveDialogProps> = ({
  open,
  application,
  onClose,
  onApprove,
  onDecline,
  isLoading = false,
}) => {
  const { t } = useTranslation();
  const [isDeclineMode, setIsDeclineMode] = useState(false);
  const [declineReason, setDeclineReason] = useState('');

  const handleApprove = useCallback(() => {
    onApprove();
  }, [onApprove]);

  const handleDeclineClick = useCallback(() => {
    setIsDeclineMode(true);
  }, []);

  const handleDeclineConfirm = useCallback(() => {
    if (declineReason.trim()) {
      onDecline(declineReason.trim());
      setDeclineReason('');
      setIsDeclineMode(false);
    }
  }, [onDecline, declineReason]);

  const handleClose = useCallback(() => {
    setIsDeclineMode(false);
    setDeclineReason('');
    onClose();
  }, [onClose]);

  if (!application) return null;

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        {isDeclineMode
          ? t('groundAdmin.declineTitle', 'Decline Application')
          : t('groundAdmin.reviewTitle', 'Review Ground Admin Application')}
      </DialogTitle>
      <DialogContent>
        {!isDeclineMode ? (
          <>
            {/* Applicant Info */}
            <Box sx={{ mb: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <PersonIcon color="action" fontSize="small" />
                <Typography variant="subtitle1" sx={{
                  fontWeight: 600
                }}>
                  {application.memberName}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CalendarTodayIcon color="action" fontSize="small" />
                <Typography variant="body2" sx={{
                  color: "text.secondary"
                }}>
                  {t('groundAdmin.appliedOn', 'Applied on {{date}}', {
                    date: formatDate(application.createdAt),
                  })}
                </Typography>
              </Box>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Typography variant="body2" sx={{
              color: "text.secondary"
            }}>
              {application.type === 'application'
                ? t(
                    'groundAdmin.applicationDescription',
                    'This member has applied to become a Ground Admin in your sector. Ground Admins can verify reported issues and fix completions.'
                  )
                : t(
                    'groundAdmin.invitationPending',
                    'This invitation is pending the member\'s response.'
                  )}
            </Typography>
          </>
        ) : (
          <>
            <Typography
              variant="body2"
              sx={{
                color: "text.secondary",
                mb: 2
              }}>
              {t(
                'groundAdmin.declineDescription',
                'Please provide a reason for declining this application. The member will be notified.'
              )}
            </Typography>
            <TextField
              autoFocus
              multiline
              rows={3}
              fullWidth
              required
              label={t('groundAdmin.declineReason', 'Reason for declining')}
              value={declineReason}
              onChange={(e) => setDeclineReason(e.target.value)}
              error={!declineReason.trim() && declineReason.length > 0}
              helperText={
                !declineReason.trim() && declineReason.length > 0
                  ? t('common.validation.required', 'This field is required')
                  : ''
              }
            />
          </>
        )}
      </DialogContent>
      <DialogActions>
        {!isDeclineMode ? (
          <>
            <Button onClick={handleClose} disabled={isLoading}>
              {t('common.buttons.cancel', 'Cancel')}
            </Button>
            <Button
              onClick={handleDeclineClick}
              color="error"
              disabled={isLoading}
            >
              {t('groundAdmin.decline', 'Decline')}
            </Button>
            <Button
              onClick={handleApprove}
              variant="contained"
              color="success"
              disabled={isLoading}
            >
              {isLoading
                ? t('common.loading', 'Loading...')
                : t('groundAdmin.approve', 'Approve')}
            </Button>
          </>
        ) : (
          <>
            <Button onClick={() => setIsDeclineMode(false)} disabled={isLoading}>
              {t('common.buttons.back', 'Back')}
            </Button>
            <Button
              onClick={handleDeclineConfirm}
              variant="contained"
              color="error"
              disabled={isLoading || !declineReason.trim()}
            >
              {isLoading
                ? t('common.loading', 'Loading...')
                : t('common.buttons.confirm', 'Confirm Decline')}
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  );
};
