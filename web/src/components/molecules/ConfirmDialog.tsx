import { type FC, type ReactNode, useId } from 'react';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import { useTranslation } from 'react-i18next';

type DialogVariant = 'default' | 'warning';
type DialogSize = 'sm' | 'md' | 'lg';

interface ConfirmDialogProps {
  /** Whether the dialog is open */
  open: boolean;
  /** Dialog title */
  title: string;
  /** Called when the dialog should close */
  onClose: () => void;
  /** Called when the confirm button is clicked */
  onConfirm: () => void;
  /** Dialog content */
  children: ReactNode;
  /** Confirm button label */
  confirmLabel?: string;
  /** Cancel button label */
  cancelLabel?: string;
  /** Dialog variant - controls header color */
  variant?: DialogVariant;
  /** Loading state - disables buttons and shows spinner */
  isLoading?: boolean;
  /** Dialog size */
  size?: DialogSize;
  /** Disable closing on backdrop click or Escape key */
  disableBackdropClose?: boolean;
}

const sizeMap: Record<DialogSize, 'xs' | 'sm' | 'md'> = {
  sm: 'xs',
  md: 'sm',
  lg: 'md',
};

export const ConfirmDialog: FC<ConfirmDialogProps> = ({
  open,
  title,
  onClose,
  onConfirm,
  children,
  confirmLabel,
  cancelLabel,
  variant = 'default',
  isLoading = false,
  size = 'md',
  disableBackdropClose = false,
}) => {
  const { t } = useTranslation();
  const titleId = useId();

  const finalConfirmLabel = confirmLabel ?? t('common.confirm');
  const finalCancelLabel = cancelLabel ?? t('common.cancel');

  const headerBgColor = variant === 'warning' ? 'warning.main' : 'secondary.main';

  const handleClose = (_event: object, reason: 'backdropClick' | 'escapeKeyDown') => {
    if (disableBackdropClose && (reason === 'backdropClick' || reason === 'escapeKeyDown')) {
      return;
    }
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth={sizeMap[size]}
      fullWidth
      aria-labelledby={titleId}
      slotProps={{
        paper: {
          sx: {
            borderRadius: 1, // 8px - matches buttons, inputs, cards
            overflow: 'hidden',
          },
        }
      }}
    >
      {/* Header */}
      <DialogTitle
        id={titleId}
        data-testid="confirm-dialog-header"
        sx={{
          bgcolor: headerBgColor,
          color: 'common.white',
          py: 1.5,
          px: 2.5,
        }}
      >
        <Typography variant="h6" component="span" sx={{
          fontWeight: 600
        }}>
          {title}
        </Typography>
      </DialogTitle>

      {/* Content */}
      <DialogContent sx={{ p: 0 }}>
        <Box sx={{ pt: 3, pb: 2.5, px: 2.5 }}>
          {children}
        </Box>
      </DialogContent>

      {/* Footer / Toolbar */}
      <DialogActions
        sx={{
          px: 2.5,
          py: 1.5,
          gap: 1,
        }}
      >
        <Button
          variant="outlined"
          color="secondary"
          onClick={onClose}
          disabled={isLoading}
        >
          {finalCancelLabel}
        </Button>
        <Button
          variant="contained"
          color="primary"
          onClick={onConfirm}
          disabled={isLoading}
          autoFocus
          startIcon={isLoading ? <CircularProgress size={16} color="inherit" /> : undefined}
        >
          {isLoading ? t('common.loading', 'Loading...') : finalConfirmLabel}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
