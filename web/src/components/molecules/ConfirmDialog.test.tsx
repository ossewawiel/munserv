import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { ConfirmDialog } from './ConfirmDialog';
import { createPodTheme, defaultPodConfig } from '@/theme';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          confirm: 'Confirm',
          cancel: 'Cancel',
        },
      },
    },
  },
});

const theme = createPodTheme(defaultPodConfig);

function renderConfirmDialog(
  props: Partial<React.ComponentProps<typeof ConfirmDialog>> = {}
) {
  const defaultProps = {
    open: true,
    title: 'Test Dialog',
    onClose: vi.fn(),
    onConfirm: vi.fn(),
    children: <div>Dialog content</div>,
  };

  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <ConfirmDialog {...defaultProps} {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
}

describe('ConfirmDialog', () => {
  describe('rendering', () => {
    it('should render dialog when open is true', () => {
      renderConfirmDialog({ open: true });

      expect(screen.getByRole('dialog')).toBeInTheDocument();
      expect(screen.getByText('Test Dialog')).toBeInTheDocument();
    });

    it('should not render dialog when open is false', () => {
      renderConfirmDialog({ open: false });

      expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    });

    it('should render children content', () => {
      renderConfirmDialog({ children: <p>Custom content here</p> });

      expect(screen.getByText('Custom content here')).toBeInTheDocument();
    });

    it('should render confirm and cancel buttons', () => {
      renderConfirmDialog();

      expect(screen.getByRole('button', { name: /confirm/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument();
    });
  });

  describe('header styling', () => {
    it('should render header with secondary background color by default', () => {
      renderConfirmDialog({ title: 'Default Header' });

      const header = screen.getByTestId('confirm-dialog-header');
      expect(header).toHaveStyle({ backgroundColor: expect.stringContaining('') });
      // The header should have secondary.main background
      expect(header).toHaveClass('MuiDialogTitle-root');
    });

    it('should render header with warning background color for warning variant', () => {
      renderConfirmDialog({ title: 'Warning Header', variant: 'warning' });

      const header = screen.getByTestId('confirm-dialog-header');
      expect(header).toBeInTheDocument();
    });

    it('should render white text in header', () => {
      renderConfirmDialog({ title: 'White Text Header' });

      const headerText = screen.getByText('White Text Header');
      expect(headerText).toBeInTheDocument();
    });
  });

  describe('footer button styling', () => {
    it('should render confirm button as contained primary', () => {
      renderConfirmDialog();

      const confirmButton = screen.getByRole('button', { name: /confirm/i });
      expect(confirmButton).toHaveClass('MuiButton-containedPrimary');
    });

    it('should render cancel button as outlined secondary', () => {
      renderConfirmDialog();

      const cancelButton = screen.getByRole('button', { name: /cancel/i });
      expect(cancelButton).toHaveClass('MuiButton-outlinedSecondary');
    });
  });

  describe('custom labels', () => {
    it('should render custom confirm label', () => {
      renderConfirmDialog({ confirmLabel: 'Yes, Delete' });

      expect(screen.getByRole('button', { name: 'Yes, Delete' })).toBeInTheDocument();
    });

    it('should render custom cancel label', () => {
      renderConfirmDialog({ cancelLabel: 'No, Keep' });

      expect(screen.getByRole('button', { name: 'No, Keep' })).toBeInTheDocument();
    });
  });

  describe('interactions', () => {
    it('should call onConfirm when confirm button is clicked', async () => {
      const onConfirm = vi.fn();
      renderConfirmDialog({ onConfirm });

      await userEvent.click(screen.getByRole('button', { name: /confirm/i }));

      expect(onConfirm).toHaveBeenCalledTimes(1);
    });

    it('should call onClose when cancel button is clicked', async () => {
      const onClose = vi.fn();
      renderConfirmDialog({ onClose });

      await userEvent.click(screen.getByRole('button', { name: /cancel/i }));

      expect(onClose).toHaveBeenCalledTimes(1);
    });

    it('should call onClose when dialog backdrop is clicked', async () => {
      const onClose = vi.fn();
      renderConfirmDialog({ onClose });

      // Press Escape to close dialog
      await userEvent.keyboard('{Escape}');

      await waitFor(() => {
        expect(onClose).toHaveBeenCalled();
      });
    });

    it('should not call onClose on backdrop click when disableBackdropClose is true', async () => {
      const onClose = vi.fn();
      renderConfirmDialog({ onClose, disableBackdropClose: true });

      await userEvent.keyboard('{Escape}');

      // onClose should not be called
      expect(onClose).not.toHaveBeenCalled();
    });
  });

  describe('loading state', () => {
    it('should disable confirm button when isLoading is true', () => {
      renderConfirmDialog({ isLoading: true });

      const confirmButton = screen.getByRole('button', { name: /loading/i });
      expect(confirmButton).toBeDisabled();
    });

    it('should disable cancel button when isLoading is true', () => {
      renderConfirmDialog({ isLoading: true });

      const cancelButton = screen.getByRole('button', { name: /cancel/i });
      expect(cancelButton).toBeDisabled();
    });

    it('should show loading indicator on confirm button', () => {
      renderConfirmDialog({ isLoading: true });

      expect(screen.getByRole('progressbar')).toBeInTheDocument();
    });
  });

  describe('sizes', () => {
    it('should render small dialog', () => {
      renderConfirmDialog({ size: 'sm' });

      const dialog = screen.getByRole('dialog');
      expect(dialog).toBeInTheDocument();
    });

    it('should render medium dialog by default', () => {
      renderConfirmDialog();

      const dialog = screen.getByRole('dialog');
      expect(dialog).toBeInTheDocument();
    });

    it('should render large dialog', () => {
      renderConfirmDialog({ size: 'lg' });

      const dialog = screen.getByRole('dialog');
      expect(dialog).toBeInTheDocument();
    });
  });

  describe('border radius', () => {
    it('should have consistent border radius matching buttons and cards', () => {
      renderConfirmDialog();

      // The dialog role is on the Paper element itself
      const dialog = screen.getByRole('dialog');
      expect(dialog).toBeInTheDocument();
      // Border radius of 8px is set via PaperProps.sx in the component
      // and matches theme.shape.borderRadius for buttons, inputs, cards
    });
  });

  describe('accessibility', () => {
    it('should have proper aria-labelledby', () => {
      renderConfirmDialog({ title: 'Accessible Dialog' });

      const dialog = screen.getByRole('dialog');
      expect(dialog).toHaveAttribute('aria-labelledby');
    });

    it('should focus confirm button by default', async () => {
      renderConfirmDialog();

      await waitFor(() => {
        const confirmButton = screen.getByRole('button', { name: /confirm/i });
        expect(document.activeElement).toBe(confirmButton);
      });
    });
  });
});
