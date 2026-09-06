import { describe, it, expect, vi } from 'vitest';
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

  it('should restart the auto-hide timer for a message that replaces one already showing', () => {
    // `requestAnimationFrame` stays real: MUI's transitions drive some of
    // their internal bookkeping off it, and faking it here makes
    // `advanceTimersByTime` block for real wall-clock time trying to
    // reconcile the two clocks instead of advancing instantly.
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'Date'] });

    render(
      <FeedbackProvider>
        <TestConsumer />
      </FeedbackProvider>
    );

    act(() => {
      screen.getByText('show-success').click();
    });
    act(() => {
      vi.advanceTimersByTime(3900);
    });

    act(() => {
      screen.getByText('show-info').click();
    });
    act(() => {
      vi.advanceTimersByTime(3800);
    });

    // The second message's own four seconds have not elapsed yet, even
    // though 7.7s have passed since the first message appeared: the timer
    // must have restarted, not carried over the first message's remainder.
    expect(screen.getByRole('alert')).toHaveTextContent('Revoked.');

    act(() => {
      vi.advanceTimersByTime(300);
    });

    expect(screen.queryByRole('alert')).not.toBeInTheDocument();

    vi.useRealTimers();
  });
});
