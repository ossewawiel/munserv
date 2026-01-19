import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import BuildIcon from '@mui/icons-material/Build';

import type { GroundAdmin } from '@/shared/types/groundAdmin';
import type { VerificationMode, VerificationType } from '@/shared/types/sectorSettings';
import type { RequestVerificationRequest } from '@/shared/types/verification';

interface Issue {
  id: string;
  type: string;
}

interface RequestVerificationDialogProps {
  open: boolean;
  issue: Issue | null;
  type: VerificationType;
  groundAdmins: GroundAdmin[];
  verificationMode: VerificationMode;
  onClose: () => void;
  onRequest: (request: RequestVerificationRequest) => void;
  isLoading?: boolean;
}

/**
 * Dialog for requesting verification from Ground Admins
 */
export const RequestVerificationDialog: FC<RequestVerificationDialogProps> = ({
  open,
  issue,
  type,
  groundAdmins,
  verificationMode,
  onClose,
  onRequest,
  isLoading = false,
}) => {
  const { t } = useTranslation();
  const [selectedGroundAdmin, setSelectedGroundAdmin] = useState<string>('');
  const [message, setMessage] = useState('');

  const isExistence = type === 'existence';

  const activeGroundAdmins = useMemo(
    () => groundAdmins.filter((ga) => ga.status === 'active'),
    [groundAdmins]
  );

  const showGroundAdminSelect = verificationMode === 'admin_assigns';

  const handleConfirm = useCallback(() => {
    const request: RequestVerificationRequest = {
      type,
      assignTo: showGroundAdminSelect && selectedGroundAdmin ? selectedGroundAdmin : undefined,
      message: message.trim() || undefined,
    };
    onRequest(request);
    setSelectedGroundAdmin('');
    setMessage('');
  }, [type, showGroundAdminSelect, selectedGroundAdmin, message, onRequest]);

  const handleClose = useCallback(() => {
    setSelectedGroundAdmin('');
    setMessage('');
    onClose();
  }, [onClose]);

  const getModeDescription = (): string => {
    switch (verificationMode) {
      case 'all_notified':
        return t(
          'verification.modeAllNotified',
          'All active Ground Admins in the sector will be notified.'
        );
      case 'admin_assigns':
        return t(
          'verification.modeAdminAssigns',
          'Select a Ground Admin to assign this verification task.'
        );
      case 'nearest_auto':
        return t(
          'verification.modeNearestAuto',
          'The system will automatically assign the nearest Ground Admin.'
        );
      case 'first_come':
        return t(
          'verification.modeFirstCome',
          'All Ground Admins will be notified. The first one to respond will handle it.'
        );
      default:
        return '';
    }
  };

  if (!issue) return null;

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        {isExistence ? (
          <VerifiedUserIcon color="primary" />
        ) : (
          <BuildIcon color="primary" />
        )}
        {isExistence
          ? t('verification.requestExistence', 'Request Existence Verification')
          : t('verification.requestFix', 'Request Fix Verification')}
      </DialogTitle>
      <DialogContent>
        <DialogContentText sx={{ mb: 2 }}>
          {isExistence
            ? t(
                'verification.existenceDescription',
                'Request a Ground Admin to physically verify that this reported issue exists at the specified location.'
              )
            : t(
                'verification.fixDescription',
                'Request a Ground Admin to physically verify that this issue has been properly fixed.'
              )}
        </DialogContentText>

        <Typography
          variant="body2"
          color="text.secondary"
          sx={{ mb: 3, p: 1.5, bgcolor: 'action.hover', borderRadius: 1 }}
        >
          {getModeDescription()}
        </Typography>

        {showGroundAdminSelect && (
          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>{t('verification.selectGroundAdmin', 'Select Ground Admin')}</InputLabel>
            <Select
              value={selectedGroundAdmin}
              label={t('verification.selectGroundAdmin', 'Select Ground Admin')}
              onChange={(e) => setSelectedGroundAdmin(e.target.value)}
              required
            >
              {activeGroundAdmins.length === 0 ? (
                <MenuItem disabled>
                  {t('verification.noActiveGroundAdmins', 'No active Ground Admins available')}
                </MenuItem>
              ) : (
                activeGroundAdmins.map((ga) => (
                  <MenuItem key={ga.memberId} value={ga.memberId}>
                    {ga.name} ({ga.responseRate}% response rate)
                  </MenuItem>
                ))
              )}
            </Select>
          </FormControl>
        )}

        <TextField
          multiline
          rows={2}
          fullWidth
          label={t('verification.optionalMessage', 'Optional message')}
          placeholder={t(
            'verification.messagePlaceholder',
            'Add any specific instructions for the Ground Admin...'
          )}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={isLoading}>
          {t('common.buttons.cancel', 'Cancel')}
        </Button>
        <Button
          onClick={handleConfirm}
          variant="contained"
          color="primary"
          disabled={
            isLoading ||
            (showGroundAdminSelect && !selectedGroundAdmin && activeGroundAdmins.length > 0)
          }
        >
          {isLoading
            ? t('common.loading', 'Loading...')
            : t('verification.sendRequest', 'Send Request')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
