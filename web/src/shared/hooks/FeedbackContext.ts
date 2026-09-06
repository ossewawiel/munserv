import { createContext } from 'react';
import type { AlertColor } from '@mui/material/Alert';

export interface FeedbackMessage {
  message: string;
  severity: AlertColor;
}

export interface FeedbackContextValue {
  showFeedback: (feedback: FeedbackMessage) => void;
}

export const FeedbackContext = createContext<FeedbackContextValue | null>(null);
