import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { RevokeInviteDialog } from './RevokeInviteDialog';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { cancel: 'Cancel', confirm: 'Confirm', loading: 'Loading...' },
        members: {
          revokeInvite: 'Revoke Invitation',
          revokeInviteConfirm:
            'Are you sure you want to revoke the Ground Admin invitation for {{name}}?',
          revokeInviteWarning:
            'This action cannot be undone. You can send a new invitation later.',
        },
      },
    },
  },
});

const theme = createTheme();

const defaultProps = {
  open: true,
  member: { id: '1', name: 'John Doe' },
  onClose: vi.fn(),
  onConfirm: vi.fn(),
  isLoading: false,
};

function renderDialog(props = defaultProps) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <RevokeInviteDialog {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
}

describe('RevokeInviteDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should render dialog with member name in header', () => {
    renderDialog();

    // Member name appears in the h6 heading (avatar section)
    expect(screen.getByRole('heading', { name: 'John Doe', level: 6 })).toBeInTheDocument();
  });

  it('should render dialog title', () => {
    renderDialog();

    // Title appears in both DialogTitle and button, use getByRole for heading
    expect(screen.getByRole('heading', { name: 'Revoke Invitation' })).toBeInTheDocument();
  });

  it('should call onConfirm when revoke button clicked', async () => {
    const onConfirm = vi.fn();
    renderDialog({ ...defaultProps, onConfirm });

    // Get the contained button (not the title)
    const revokeButton = screen.getByRole('button', { name: /revoke invitation/i });
    await fireEvent.click(revokeButton);
    expect(onConfirm).toHaveBeenCalled();
  });

  it('should call onClose when cancel clicked', async () => {
    const onClose = vi.fn();
    renderDialog({ ...defaultProps, onClose });

    await fireEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onClose).toHaveBeenCalled();
  });

  it('should disable buttons when loading', () => {
    renderDialog({ ...defaultProps, isLoading: true });

    expect(screen.getByRole('button', { name: /cancel/i })).toBeDisabled();
    // When loading, button text changes to "Loading..."
    const loadingButton = screen.getByRole('button', { name: /loading/i });
    expect(loadingButton).toBeDisabled();
  });

  it('should not render when closed', () => {
    renderDialog({ ...defaultProps, open: false });

    expect(screen.queryByText('Revoke Invitation')).not.toBeInTheDocument();
  });

  it('should not render when member is null', () => {
    const { container } = renderDialog({
      ...defaultProps,
      member: null as unknown as { id: string; name: string },
    });

    // Component returns null when member is null
    expect(container.querySelector('[role="dialog"]')).not.toBeInTheDocument();
  });
});
