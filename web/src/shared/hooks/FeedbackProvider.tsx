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
  // MUI's Snackbar only restarts its auto-hide timer when `open` or
  // `autoHideDuration` change (see useSnackbar's effect deps); neither does
  // here, since `open` is the literal `true` and `autoHideDuration` is a
  // module constant. A replacement message would otherwise inherit whatever
  // is left of the previous one's four seconds, so remount the snackbar
  // per message with a sequence number as its key instead.
  const [seq, setSeq] = useState(0);

  const showFeedback = useCallback((next: FeedbackMessage) => {
    setFeedback(next);
    setSeq((current) => current + 1);
  }, []);

  const handleClose = useCallback(() => {
    setFeedback(null);
  }, []);

  const value = useMemo(() => ({ showFeedback }), [showFeedback]);

  return (
    <FeedbackContext.Provider value={value}>
      {children}
      <FeedbackSnackbar key={seq} feedback={feedback} onClose={handleClose} />
    </FeedbackContext.Provider>
  );
};
