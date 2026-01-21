import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MessageList } from './MessageList';
import type { Message } from '@/shared/types/message';

// Mock i18n
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, fallback?: string) => fallback || key,
  }),
}));

// Mock formatters
vi.mock('@/shared/utils/formatters', () => ({
  formatRelativeTime: (date: string) => `relative(${date})`,
}));

const mockMessages: Message[] = [
  {
    id: 'msg-1',
    type: 'ground_admin_application',
    title: 'Ground Admin Application',
    body: 'John Smith has applied to become a Ground Admin.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    status: 'unread',
    actionType: 'approve_reject',
    createdAt: '2026-01-19T10:00:00Z',
  },
  {
    id: 'msg-2',
    type: 'verify_new_issue',
    title: 'Verify New Issue',
    body: 'A new pothole has been reported.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    status: 'read',
    actionType: 'confirm_verify',
    createdAt: '2026-01-18T09:00:00Z',
  },
  {
    id: 'msg-3',
    type: 'monthly_report',
    title: 'Monthly Report',
    body: 'Your sector resolved 45 issues this month.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    status: 'actioned',
    actionType: 'view',
    createdAt: '2026-01-15T08:00:00Z',
  },
];

describe('MessageList', () => {
  describe('rendering', () => {
    it('should render all messages', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      expect(screen.getByText('Ground Admin Application')).toBeInTheDocument();
      expect(screen.getByText('Verify New Issue')).toBeInTheDocument();
      expect(screen.getByText('Monthly Report')).toBeInTheDocument();
    });

    it('should display message body preview', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      expect(
        screen.getByText('John Smith has applied to become a Ground Admin.')
      ).toBeInTheDocument();
    });

    it('should display relative time for each message', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      // formatRelativeTime mock returns "relative(date)"
      expect(screen.getByText('relative(2026-01-19T10:00:00Z)')).toBeInTheDocument();
    });

    it('should sort messages by newest first', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      const listItems = screen.getAllByRole('button');
      // First message should be the newest (msg-1)
      expect(listItems[0]).toHaveTextContent('Ground Admin Application');
    });

    it('should display unread indicator for unread messages', () => {
      const onSelect = vi.fn();
      const { container } = render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      // Unread message (msg-1) should have the CircleIcon indicator
      // The first list item should contain the unread indicator
      const circleIcons = container.querySelectorAll('[data-testid="CircleIcon"]');
      expect(circleIcons.length).toBeGreaterThan(0);
    });

    it('should highlight selected message', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          selectedId="msg-2"
          onSelect={onSelect}
        />
      );

      const selectedItem = screen.getByText('Verify New Issue').closest('div[role="button"]');
      expect(selectedItem).toHaveClass('Mui-selected');
    });
  });

  describe('loading state', () => {
    it('should show skeleton when loading', () => {
      const onSelect = vi.fn();
      const { container } = render(
        <MessageList
          messages={[]}
          onSelect={onSelect}
          isLoading={true}
        />
      );

      const skeletons = container.querySelectorAll('.MuiSkeleton-root');
      expect(skeletons.length).toBeGreaterThan(0);
    });

    it('should not show messages when loading', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
          isLoading={true}
        />
      );

      expect(screen.queryByText('Ground Admin Application')).not.toBeInTheDocument();
    });
  });

  describe('empty state', () => {
    it('should show empty message when no messages', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={[]}
          onSelect={onSelect}
        />
      );

      expect(screen.getByText('No messages')).toBeInTheDocument();
    });

    it('should show empty icon when no messages', () => {
      const onSelect = vi.fn();
      const { container } = render(
        <MessageList
          messages={[]}
          onSelect={onSelect}
        />
      );

      // MarkEmailReadIcon should be rendered
      const icon = container.querySelector('[data-testid="MarkEmailReadIcon"]');
      expect(icon).toBeInTheDocument();
    });
  });

  describe('selection', () => {
    it('should call onSelect when message is clicked', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      fireEvent.click(screen.getByText('Ground Admin Application'));
      expect(onSelect).toHaveBeenCalledWith(mockMessages[0]);
    });

    it('should call onSelect with correct message object', () => {
      const onSelect = vi.fn();
      render(
        <MessageList
          messages={mockMessages}
          onSelect={onSelect}
        />
      );

      fireEvent.click(screen.getByText('Verify New Issue'));
      expect(onSelect).toHaveBeenCalledWith(mockMessages[1]);
    });
  });
});
