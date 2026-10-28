import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';

import { FeedbackSnackbar } from './FeedbackSnackbar';

describe('FeedbackSnackbar', () => {
  it('should render the message with the given severity', () => {
    render(<FeedbackSnackbar feedback={{ message: 'Saved.', severity: 'success' }} onClose={vi.fn()} />);

    const alert = screen.getByRole('alert');
    expect(alert).toHaveTextContent('Saved.');
    expect(alert).toHaveClass('MuiAlert-filled', 'MuiAlert-colorSuccess');
  });

  it('should call onClose when it auto-hides', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    const onClose = vi.fn();

    render(<FeedbackSnackbar feedback={{ message: 'Saved.', severity: 'success' }} onClose={onClose} />);

    vi.advanceTimersByTime(4000);

    await waitFor(() => expect(onClose).toHaveBeenCalled());
    vi.useRealTimers();
  });

  it('should render nothing without a message', () => {
    const { container } = render(<FeedbackSnackbar feedback={null} onClose={vi.fn()} />);

    expect(container).toBeEmptyDOMElement();
  });
});
