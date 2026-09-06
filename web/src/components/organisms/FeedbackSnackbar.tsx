import { type FC } from 'react';
import Snackbar from '@mui/material/Snackbar';
import Alert, { type AlertColor } from '@mui/material/Alert';

const AUTO_HIDE_DURATION_MS = 4000;

export interface Feedback {
  message: string;
  severity: AlertColor;
}

interface FeedbackSnackbarProps {
  feedback: Feedback | null;
  onClose: () => void;
}

/**
 * The one shared bottom-centre snackbar for a transient outcome (saved,
 * revoked, sent...). See design/registry/web.md's Feedback section: a
 * persistent problem the user must act on stays as an inline Alert next to
 * the form it belongs to, never in here. Renders nothing without a message,
 * and shows one message at a time - a new one replaces the one on screen.
 */
export const FeedbackSnackbar: FC<FeedbackSnackbarProps> = ({ feedback, onClose }) => {
  if (!feedback) {
    return null;
  }

  return (
    <Snackbar
      open
      anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      autoHideDuration={AUTO_HIDE_DURATION_MS}
      onClose={onClose}
    >
      <Alert variant="filled" severity={feedback.severity} elevation={6}>
        {feedback.message}
      </Alert>
    </Snackbar>
  );
};
