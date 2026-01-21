import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MessageDetail } from './MessageDetail';
import type { Message } from '@/shared/types/message';
import { MESSAGE_ACTION_TYPES } from '@/shared/types/message';

// Mock i18n
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, fallback?: string) => fallback || key,
  }),
}));

// Mock formatters
vi.mock('@/shared/utils/formatters', () => ({
  formatDateTime: (date: string) => `formatted(${date})`,
}));

const createMessage = (overrides: Partial<Message> = {}): Message => ({
  id: 'msg-1',
  type: 'ground_admin_application',
  title: 'Ground Admin Application',
  body: 'John Smith has applied to become a Ground Admin in your sector.',
  recipientId: 'admin-1',
  recipientType: 'admin',
  senderId: 'member-1',
  senderType: 'member',
  status: 'unread',
  actionType: MESSAGE_ACTION_TYPES.APPROVE_REJECT,
  createdAt: '2026-01-19T10:00:00Z',
  ...overrides,
});

describe('MessageDetail', () => {
  describe('rendering', () => {
    it('should render message title', () => {
      render(
        <MessageDetail
          message={createMessage()}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('Ground Admin Application')).toBeInTheDocument();
    });

    it('should render message body', () => {
      render(
        <MessageDetail
          message={createMessage()}
          onAction={vi.fn()}
        />
      );

      expect(
        screen.getByText('John Smith has applied to become a Ground Admin in your sector.')
      ).toBeInTheDocument();
    });

    it('should render status chip', () => {
      render(
        <MessageDetail
          message={createMessage({ status: 'read' })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('read')).toBeInTheDocument();
    });

    it('should render formatted date', () => {
      render(
        <MessageDetail
          message={createMessage()}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('formatted(2026-01-19T10:00:00Z)')).toBeInTheDocument();
    });

    it('should render metadata if present', () => {
      const messageWithMetadata = createMessage({
        metadata: {
          memberSince: '2024-01-15',
          issuesReported: 47,
        },
      });

      render(
        <MessageDetail
          message={messageWithMetadata}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('Additional Information')).toBeInTheDocument();
      expect(screen.getByText('memberSince:')).toBeInTheDocument();
      expect(screen.getByText('2024-01-15')).toBeInTheDocument();
      expect(screen.getByText('issuesReported:')).toBeInTheDocument();
      expect(screen.getByText('47')).toBeInTheDocument();
    });

    it('should render related entity chip if present', () => {
      const messageWithRelated = createMessage({
        relatedEntityId: 'member-1',
        relatedEntityType: 'member',
      });

      render(
        <MessageDetail
          message={messageWithRelated}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('member: member-1')).toBeInTheDocument();
    });
  });

  describe('APPROVE_REJECT action type', () => {
    it('should render Approve and Reject buttons', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.APPROVE_REJECT })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByRole('button', { name: /approve/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /reject/i })).toBeInTheDocument();
    });

    it('should call onAction with approve when Approve is clicked', () => {
      const onAction = vi.fn();
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.APPROVE_REJECT })}
          onAction={onAction}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /approve/i }));
      expect(onAction).toHaveBeenCalledWith('approve');
    });

    it('should open decline dialog when Reject is clicked', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.APPROVE_REJECT })}
          onAction={vi.fn()}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /reject/i }));
      expect(screen.getByText('Reason for Declining')).toBeInTheDocument();
    });
  });

  describe('ACCEPT_DECLINE action type', () => {
    it('should render Accept and Decline buttons', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByRole('button', { name: /accept/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /decline/i })).toBeInTheDocument();
    });

    it('should call onAction with accept when Accept is clicked', () => {
      const onAction = vi.fn();
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={onAction}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /accept/i }));
      expect(onAction).toHaveBeenCalledWith('accept');
    });
  });

  describe('CONFIRM_VERIFY action type', () => {
    it('should render Confirm and Cannot Verify buttons', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.CONFIRM_VERIFY })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByRole('button', { name: /confirm/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /cannot verify/i })).toBeInTheDocument();
    });

    it('should call onAction with confirm when Confirm is clicked', () => {
      const onAction = vi.fn();
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.CONFIRM_VERIFY })}
          onAction={onAction}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /confirm/i }));
      expect(onAction).toHaveBeenCalledWith('confirm');
    });
  });

  describe('ACKNOWLEDGE action type', () => {
    it('should render Dismiss button', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACKNOWLEDGE })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByRole('button', { name: /dismiss/i })).toBeInTheDocument();
    });

    it('should call onAction with dismiss when Dismiss is clicked', () => {
      const onAction = vi.fn();
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACKNOWLEDGE })}
          onAction={onAction}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /dismiss/i }));
      expect(onAction).toHaveBeenCalledWith('dismiss');
    });
  });

  describe('VIEW action type', () => {
    it('should not render action buttons', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.VIEW })}
          onAction={vi.fn()}
        />
      );

      expect(screen.queryByRole('button', { name: /approve/i })).not.toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /accept/i })).not.toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /confirm/i })).not.toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /dismiss/i })).not.toBeInTheDocument();
    });
  });

  describe('actioned state', () => {
    it('should show actioned chip instead of buttons when already actioned', () => {
      render(
        <MessageDetail
          message={createMessage({
            status: 'actioned',
            actionResult: 'approved',
          })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('approved')).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /approve/i })).not.toBeInTheDocument();
    });

    it('should show dismissed chip when status is dismissed', () => {
      render(
        <MessageDetail
          message={createMessage({
            status: 'dismissed',
          })}
          onAction={vi.fn()}
        />
      );

      expect(screen.getByText('Actioned')).toBeInTheDocument();
    });
  });

  describe('decline dialog', () => {
    it('should open dialog when decline button is clicked', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={vi.fn()}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /decline/i }));
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    it('should have disabled confirm button when reason is empty', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={vi.fn()}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /decline/i }));

      const confirmButton = screen.getByRole('button', { name: /confirm/i });
      expect(confirmButton).toBeDisabled();
    });

    it('should enable confirm button when reason is provided', async () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={vi.fn()}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /decline/i }));

      const textarea = screen.getByLabelText(/please provide a reason/i);
      fireEvent.change(textarea, { target: { value: 'Not eligible' } });

      await waitFor(() => {
        const confirmButton = screen.getByRole('button', { name: /confirm/i });
        expect(confirmButton).not.toBeDisabled();
      });
    });

    it('should call onAction with decline and reason when confirmed', async () => {
      const onAction = vi.fn();
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={onAction}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /decline/i }));

      const textarea = screen.getByLabelText(/please provide a reason/i);
      fireEvent.change(textarea, { target: { value: 'Not eligible' } });

      fireEvent.click(screen.getByRole('button', { name: /confirm/i }));

      expect(onAction).toHaveBeenCalledWith('decline', 'Not eligible');
    });

    it('should close dialog when cancel is clicked', async () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={vi.fn()}
        />
      );

      fireEvent.click(screen.getByRole('button', { name: /decline/i }));
      expect(screen.getByRole('dialog')).toBeInTheDocument();

      fireEvent.click(screen.getByRole('button', { name: /cancel/i }));

      await waitFor(() => {
        expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
      });
    });

    it('should clear reason when dialog is closed', async () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.ACCEPT_DECLINE })}
          onAction={vi.fn()}
        />
      );

      // Open dialog and enter reason
      fireEvent.click(screen.getByRole('button', { name: /decline/i }));
      const textarea = screen.getByLabelText(/please provide a reason/i);
      fireEvent.change(textarea, { target: { value: 'Not eligible' } });

      // Cancel
      fireEvent.click(screen.getByRole('button', { name: /cancel/i }));

      await waitFor(() => {
        expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
      });

      // Reopen - reason should be cleared
      fireEvent.click(screen.getByRole('button', { name: /decline/i }));
      const newTextarea = screen.getByLabelText(/please provide a reason/i);
      expect(newTextarea).toHaveValue('');
    });
  });

  describe('loading state', () => {
    it('should disable buttons when isActioning is true', () => {
      render(
        <MessageDetail
          message={createMessage({ actionType: MESSAGE_ACTION_TYPES.APPROVE_REJECT })}
          onAction={vi.fn()}
          isActioning={true}
        />
      );

      expect(screen.getByRole('button', { name: /approve/i })).toBeDisabled();
      expect(screen.getByRole('button', { name: /reject/i })).toBeDisabled();
    });
  });
});
