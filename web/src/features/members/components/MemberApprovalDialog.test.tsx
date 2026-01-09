import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { MemberApprovalDialog } from './MemberApprovalDialog';
import type { MemberListItem } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { cancel: 'Cancel' },
        members: {
          approve: 'Approve',
          reject: 'Reject',
          approveTitle: 'Approve Member Registration',
          rejectTitle: 'Reject Member Registration',
          approveConfirmation:
            "Are you sure you want to approve this member's registration?",
          rejectConfirmation:
            "Are you sure you want to reject this member's registration?",
          approveEmailNote:
            'A welcome email with login credentials will be sent to the member.',
          rejectWarning:
            'This will permanently delete the registration. The member will need to register again if they wish to join.',
        },
      },
    },
  },
});

const theme = createTheme();

const mockMember: MemberListItem = {
  id: 'member-1',
  firstName: 'John',
  surname: 'Doe',
  email: 'john@example.com',
  phoneNumber: '+27123456789',
  address: '123 Main Street',
  status: 'pending_approval',
  issueCount: 0,
  joinedAt: '2024-03-01T14:30:00Z',
};

interface RenderOptions {
  open?: boolean;
  action?: 'approve' | 'reject';
  member?: MemberListItem | null;
  isLoading?: boolean;
  onConfirm?: () => void;
  onCancel?: () => void;
}

function renderDialog({
  open = true,
  action = 'approve',
  member = mockMember,
  isLoading = false,
  onConfirm = vi.fn(),
  onCancel = vi.fn(),
}: RenderOptions = {}) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <MemberApprovalDialog
          open={open}
          action={action}
          member={member}
          isLoading={isLoading}
          onConfirm={onConfirm}
          onCancel={onCancel}
        />
      </I18nextProvider>
    </ThemeProvider>
  );
}

describe('MemberApprovalDialog', () => {
  describe('rendering', () => {
    it('should not render when member is null', () => {
      renderDialog({ member: null });
      expect(
        screen.queryByText('Approve Member Registration')
      ).not.toBeInTheDocument();
    });

    it('should render approve dialog with correct title', () => {
      renderDialog({ action: 'approve' });
      expect(screen.getByText('Approve Member Registration')).toBeInTheDocument();
    });

    it('should render reject dialog with correct title', () => {
      renderDialog({ action: 'reject' });
      expect(screen.getByText('Reject Member Registration')).toBeInTheDocument();
    });

    it('should display member name', () => {
      renderDialog();
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    it('should display member email', () => {
      renderDialog();
      expect(screen.getByText('john@example.com')).toBeInTheDocument();
    });

    it('should display member phone number', () => {
      renderDialog();
      expect(screen.getByText('+27123456789')).toBeInTheDocument();
    });

    it('should display member initials in avatar', () => {
      renderDialog();
      expect(screen.getByText('JD')).toBeInTheDocument();
    });
  });

  describe('approve action', () => {
    it('should show approve confirmation message', () => {
      renderDialog({ action: 'approve' });
      expect(
        screen.getByText(
          "Are you sure you want to approve this member's registration?"
        )
      ).toBeInTheDocument();
    });

    it('should show email note for approve action', () => {
      renderDialog({ action: 'approve' });
      expect(
        screen.getByText(
          'A welcome email with login credentials will be sent to the member.'
        )
      ).toBeInTheDocument();
    });

    it('should show Approve button', () => {
      renderDialog({ action: 'approve' });
      expect(screen.getByRole('button', { name: /approve/i })).toBeInTheDocument();
    });
  });

  describe('reject action', () => {
    it('should show reject confirmation message', () => {
      renderDialog({ action: 'reject' });
      expect(
        screen.getByText(
          "Are you sure you want to reject this member's registration?"
        )
      ).toBeInTheDocument();
    });

    it('should show warning for reject action', () => {
      renderDialog({ action: 'reject' });
      expect(
        screen.getByText(
          'This will permanently delete the registration. The member will need to register again if they wish to join.'
        )
      ).toBeInTheDocument();
    });

    it('should show Reject button', () => {
      renderDialog({ action: 'reject' });
      expect(screen.getByRole('button', { name: /reject/i })).toBeInTheDocument();
    });
  });

  describe('interactions', () => {
    it('should call onConfirm when confirm button is clicked', async () => {
      const onConfirm = vi.fn();
      renderDialog({ onConfirm });

      await userEvent.click(screen.getByRole('button', { name: /approve/i }));

      expect(onConfirm).toHaveBeenCalledTimes(1);
    });

    it('should call onCancel when cancel button is clicked', async () => {
      const onCancel = vi.fn();
      renderDialog({ onCancel });

      await userEvent.click(screen.getByRole('button', { name: /cancel/i }));

      expect(onCancel).toHaveBeenCalledTimes(1);
    });

    it('should disable buttons when loading', () => {
      renderDialog({ isLoading: true });

      expect(screen.getByRole('button', { name: /cancel/i })).toBeDisabled();
    });
  });
});
