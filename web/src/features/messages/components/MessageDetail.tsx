import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Divider from '@mui/material/Divider';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import ThumbUpIcon from '@mui/icons-material/ThumbUp';
import ThumbDownIcon from '@mui/icons-material/ThumbDown';
import VisibilityIcon from '@mui/icons-material/Visibility';
import ArchiveIcon from '@mui/icons-material/Archive';
import InboxIcon from '@mui/icons-material/Inbox';

import type { Message } from '@/shared/types/message';
import { MESSAGE_ACTION_TYPES } from '@/shared/types/message';
import { formatDateTime } from '@/shared/utils/formatters';

interface MessageDetailProps {
  message: Message;
  onAction: (action: string, note?: string) => void;
  isActioning?: boolean;
}

/**
 * Get status chip color
 */
function getStatusColor(
  status: Message['status']
): 'default' | 'primary' | 'success' | 'warning' {
  switch (status) {
    case 'unread':
      return 'primary';
    case 'read':
      return 'default';
    case 'actioned':
      return 'success';
    case 'dismissed':
      return 'warning';
    default:
      return 'default';
  }
}

/**
 * Message detail view with action buttons
 */
export const MessageDetail: FC<MessageDetailProps> = ({
  message,
  onAction,
  isActioning = false,
}) => {
  const { t } = useTranslation();
  const [declineDialogOpen, setDeclineDialogOpen] = useState(false);
  const [declineReason, setDeclineReason] = useState('');

  const handleAction = useCallback(
    (action: string) => {
      onAction(action);
    },
    [onAction]
  );

  const handleDeclineClick = useCallback(() => {
    setDeclineDialogOpen(true);
  }, []);

  const handleDeclineConfirm = useCallback(() => {
    onAction('decline', declineReason);
    setDeclineDialogOpen(false);
    setDeclineReason('');
  }, [onAction, declineReason]);

  const handleDeclineCancel = useCallback(() => {
    setDeclineDialogOpen(false);
    setDeclineReason('');
  }, []);

  const actionButtons = useMemo(() => {
    const { actionType, status } = message;

    // If already actioned or dismissed, don't show action buttons
    if (status === 'actioned' || status === 'dismissed') {
      return (
        <Chip
          label={
            message.actionResult
              ? t(`messages.actionResults.${message.actionResult}`, message.actionResult)
              : t('messages.actioned', 'Actioned')
          }
          color="success"
          size="small"
          icon={<CheckCircleIcon />}
        />
      );
    }

    switch (actionType) {
      case MESSAGE_ACTION_TYPES.ACCEPT_DECLINE:
        return (
          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              color="success"
              startIcon={<CheckCircleIcon />}
              onClick={() => handleAction('accept')}
              disabled={isActioning}
            >
              {t('messages.actions.accept', 'Accept')}
            </Button>
            <Button
              variant="outlined"
              color="error"
              startIcon={<CancelIcon />}
              onClick={handleDeclineClick}
              disabled={isActioning}
            >
              {t('messages.actions.decline', 'Decline')}
            </Button>
          </Stack>
        );

      case MESSAGE_ACTION_TYPES.APPROVE_REJECT:
        return (
          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              color="success"
              startIcon={<ThumbUpIcon />}
              onClick={() => handleAction('approve')}
              disabled={isActioning}
            >
              {t('messages.actions.approve', 'Approve')}
            </Button>
            <Button
              variant="outlined"
              color="error"
              startIcon={<ThumbDownIcon />}
              onClick={handleDeclineClick}
              disabled={isActioning}
            >
              {t('messages.actions.reject', 'Reject')}
            </Button>
          </Stack>
        );

      case MESSAGE_ACTION_TYPES.CONFIRM_VERIFY:
        return (
          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              color="success"
              startIcon={<CheckCircleIcon />}
              onClick={() => handleAction('confirm')}
              disabled={isActioning}
            >
              {t('messages.actions.confirm', 'Confirm')}
            </Button>
            <Button
              variant="outlined"
              color="warning"
              startIcon={<VisibilityIcon />}
              onClick={handleDeclineClick}
              disabled={isActioning}
            >
              {t('messages.actions.cannotVerify', 'Cannot Verify')}
            </Button>
          </Stack>
        );

      case MESSAGE_ACTION_TYPES.ACKNOWLEDGE:
        return (
          <Button
            variant="contained"
            startIcon={<ArchiveIcon />}
            onClick={() => handleAction('dismiss')}
            disabled={isActioning}
          >
            {t('messages.actions.dismiss', 'Dismiss')}
          </Button>
        );

      case MESSAGE_ACTION_TYPES.VIEW:
      default:
        return null;
    }
  }, [message, t, handleAction, handleDeclineClick, isActioning]);

  return (
    <Box sx={{ p: 3, height: '100%', overflow: 'auto' }}>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-start',
            mb: 2,
          }}
        >
          <Typography variant="h5" component="h2">
            {message.title}
          </Typography>
          <Chip
            label={t(`messages.status.${message.status}`, message.status)}
            color={getStatusColor(message.status)}
            size="small"
          />
        </Box>
        <Typography variant="caption" color="text.secondary">
          {formatDateTime(message.createdAt)}
        </Typography>
      </Box>

      <Divider sx={{ mb: 3 }} />

      {/* Body */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="body1" sx={{ whiteSpace: 'pre-wrap' }}>
          {message.body}
        </Typography>
      </Box>

      {/* Metadata */}
      {message.metadata && Object.keys(message.metadata).length > 0 && (
        <Box sx={{ mb: 4 }}>
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>
            {t('messages.additionalInfo', 'Additional Information')}
          </Typography>
          <Box
            sx={{
              bgcolor: 'background.paper',
              border: '1px solid',
              borderColor: 'divider',
              borderRadius: 1,
              p: 2,
            }}
          >
            {Object.entries(message.metadata).map(([key, value]) => (
              <Box key={key} sx={{ mb: 1 }}>
                <Typography variant="caption" color="text.secondary">
                  {key}:
                </Typography>{' '}
                <Typography variant="body2" component="span">
                  {String(value)}
                </Typography>
              </Box>
            ))}
          </Box>
        </Box>
      )}

      {/* Related Entity Link */}
      {message.relatedEntityId && (
        <Box sx={{ mb: 4 }}>
          <Chip
            icon={<InboxIcon />}
            label={`${message.relatedEntityType}: ${message.relatedEntityId}`}
            variant="outlined"
            size="small"
          />
        </Box>
      )}

      <Divider sx={{ mb: 3 }} />

      {/* Actions */}
      <Box>{actionButtons}</Box>

      {/* Decline Dialog */}
      <Dialog open={declineDialogOpen} onClose={handleDeclineCancel} maxWidth="sm" fullWidth>
        <DialogTitle>
          {t('messages.declineReason', 'Reason for Declining')}
        </DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            multiline
            rows={3}
            fullWidth
            label={t('messages.reasonLabel', 'Please provide a reason')}
            value={declineReason}
            onChange={(e) => setDeclineReason(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDeclineCancel}>
            {t('common.buttons.cancel', 'Cancel')}
          </Button>
          <Button
            onClick={handleDeclineConfirm}
            color="error"
            variant="contained"
            disabled={!declineReason.trim()}
          >
            {t('common.buttons.confirm', 'Confirm')}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
