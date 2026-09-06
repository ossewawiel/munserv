import { useState, useCallback, useMemo, type FC, type ReactNode } from 'react';

import { FeedbackSnackbar } from '@/components/organisms/FeedbackSnackbar';
import { FeedbackContext, type FeedbackMessage } from './FeedbackContext';

interface FeedbackProviderProps {
  children: ReactNode;
}

/**
 * Owns the single message shown by the shared FeedbackSnackbar (see
 * design/registry/web.md's Feedback section). A page never renders its own
 * Snackbar - it calls useFeedback().showFeedback(...) instead, and a new
 * message replaces whatever is currently on screen.
 */
export const FeedbackProvider: FC<FeedbackProviderProps> = ({ children }) => {
  const [feedback, setFeedback] = useState<FeedbackMessage | null>(null);

  const showFeedback = useCallback((next: FeedbackMessage) => {
    setFeedback(next);
  }, []);

  const handleClose = useCallback(() => {
    setFeedback(null);
  }, []);

  const value = useMemo(() => ({ showFeedback }), [showFeedback]);

  return (
    <FeedbackContext.Provider value={value}>
      {children}
      <FeedbackSnackbar feedback={feedback} onClose={handleClose} />
    </FeedbackContext.Provider>
  );
};
