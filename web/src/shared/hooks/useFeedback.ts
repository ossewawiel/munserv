import { useContext } from 'react';

import { FeedbackContext, type FeedbackContextValue } from './FeedbackContext';

/**
 * Access the shared feedback snackbar. Must be used within a
 * FeedbackProvider (mounted once in DashboardLayout).
 */
export function useFeedback(): FeedbackContextValue {
  const context = useContext(FeedbackContext);
  if (!context) {
    throw new Error('useFeedback must be used within a FeedbackProvider');
  }
  return context;
}
