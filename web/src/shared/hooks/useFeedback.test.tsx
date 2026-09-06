import { describe, it, expect } from 'vitest';
import { render, screen, act } from '@testing-library/react';

import { FeedbackProvider } from './FeedbackProvider';
import { useFeedback } from './useFeedback';

function TestConsumer() {
  const { showFeedback } = useFeedback();

  return (
    <>
      <button onClick={() => showFeedback({ message: 'Saved.', severity: 'success' })}>
        show-success
      </button>
      <button onClick={() => showFeedback({ message: 'Revoked.', severity: 'info' })}>
        show-info
      </button>
    </>
  );
}

describe('useFeedback', () => {
  it('should expose the last message shown', () => {
    render(
      <FeedbackProvider>
        <TestConsumer />
      </FeedbackProvider>
    );

    act(() => {
      screen.getByText('show-success').click();
    });

    expect(screen.getByRole('alert')).toHaveTextContent('Saved.');
  });

  it('should replace an earlier message', () => {
    render(
      <FeedbackProvider>
        <TestConsumer />
      </FeedbackProvider>
    );

    act(() => {
      screen.getByText('show-success').click();
    });
    act(() => {
      screen.getByText('show-info').click();
    });

    const alerts = screen.getAllByRole('alert');
    expect(alerts).toHaveLength(1);
    expect(alerts[0]).toHaveTextContent('Revoked.');
  });
});
