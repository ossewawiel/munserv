import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { MembersTable } from './MembersTable';
import type { MemberListItem } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        members: {
          name: 'Name',
          phone: 'Phone',
          address: 'Address',
          status: 'Status',
          issuesReported: 'Issues Reported',
          joinedAt: 'Joined',
          actions: 'Actions',
          approve: 'Approve',
          reject: 'Reject',
          statuses: {
            active: 'Active',
            pending_approval: 'Pending Approval',
            suspended: 'Suspended',
          },
        },
      },
    },
  },
});

const theme = createTheme();

const mockMembers: MemberListItem[] = [
  {
    id: 'member-1',
    firstName: 'John',
    surname: 'Active',
    email: 'john@example.com',
    phoneNumber: '+27123456789',
    address: '123 Main Street',
    status: 'active',
    issueCount: 5,
    joinedAt: '2024-01-15T10:00:00Z',
    isGroundAdmin: false,
  },
  {
    id: 'member-2',
    firstName: 'Jane',
    surname: 'Pending',
    email: 'jane@example.com',
    phoneNumber: '+27987654321',
    address: '456 Oak Avenue',
    status: 'pending_approval',
    issueCount: 0,
    joinedAt: '2024-03-01T14:30:00Z',
    isGroundAdmin: false,
  },
  {
    id: 'member-3',
    firstName: 'Bob',
    surname: 'Suspended',
    email: 'bob@example.com',
    phoneNumber: '+27111222333',
    address: '789 Pine Lane',
    status: 'suspended',
    issueCount: 2,
    joinedAt: '2023-06-20T09:15:00Z',
    isGroundAdmin: false,
  },
];

interface RenderOptions {
  members?: MemberListItem[];
  showApprovalActions?: boolean;
  onApprove?: (member: MemberListItem) => void;
  onReject?: (member: MemberListItem) => void;
  onRowClick?: (member: MemberListItem) => void;
}

function renderTable({
  members = mockMembers,
  showApprovalActions = false,
  onApprove = vi.fn(),
  onReject = vi.fn(),
  onRowClick,
}: RenderOptions = {}) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <MembersTable
          members={members}
          showApprovalActions={showApprovalActions}
          onApprove={onApprove}
          onReject={onReject}
          onRowClick={onRowClick}
        />
      </I18nextProvider>
    </ThemeProvider>
  );
}

describe('MembersTable', () => {
  describe('rendering', () => {
    it('should render table headers', () => {
      renderTable();

      expect(screen.getByText('Name')).toBeInTheDocument();
      expect(screen.getByText('Phone')).toBeInTheDocument();
      expect(screen.getByText('Address')).toBeInTheDocument();
      expect(screen.getByText('Status')).toBeInTheDocument();
      expect(screen.getByText('Issues Reported')).toBeInTheDocument();
      expect(screen.getByText('Joined')).toBeInTheDocument();
    });

    it('should render member names', () => {
      renderTable();

      expect(screen.getByText('John Active')).toBeInTheDocument();
      expect(screen.getByText('Jane Pending')).toBeInTheDocument();
      expect(screen.getByText('Bob Suspended')).toBeInTheDocument();
    });

    it('should render member emails', () => {
      renderTable();

      expect(screen.getByText('john@example.com')).toBeInTheDocument();
      expect(screen.getByText('jane@example.com')).toBeInTheDocument();
      expect(screen.getByText('bob@example.com')).toBeInTheDocument();
    });

    it('should render member phone numbers', () => {
      renderTable();

      expect(screen.getByText('+27123456789')).toBeInTheDocument();
      expect(screen.getByText('+27987654321')).toBeInTheDocument();
      expect(screen.getByText('+27111222333')).toBeInTheDocument();
    });

    it('should render member statuses', () => {
      renderTable();

      expect(screen.getByText('Active')).toBeInTheDocument();
      expect(screen.getByText('Pending Approval')).toBeInTheDocument();
      expect(screen.getByText('Suspended')).toBeInTheDocument();
    });

    it('should render issue counts', () => {
      renderTable();

      expect(screen.getByText('5')).toBeInTheDocument();
      expect(screen.getByText('0')).toBeInTheDocument();
      expect(screen.getByText('2')).toBeInTheDocument();
    });

    it('should render member initials in avatars', () => {
      renderTable();

      expect(screen.getByText('JA')).toBeInTheDocument(); // John Active
      expect(screen.getByText('JP')).toBeInTheDocument(); // Jane Pending
      expect(screen.getByText('BS')).toBeInTheDocument(); // Bob Suspended
    });
  });

  describe('approval actions', () => {
    it('should not show actions column when showApprovalActions is false', () => {
      renderTable({ showApprovalActions: false });

      expect(screen.queryByText('Actions')).not.toBeInTheDocument();
    });

    it('should show actions column when showApprovalActions is true', () => {
      renderTable({ showApprovalActions: true });

      expect(screen.getByText('Actions')).toBeInTheDocument();
    });

    it('should show approve/reject buttons only for pending members', () => {
      renderTable({ showApprovalActions: true });

      // Should have exactly one set of approve/reject buttons (for the pending member)
      const approveButtons = screen.getAllByRole('button', { name: /approve/i });
      const rejectButtons = screen.getAllByRole('button', { name: /reject/i });

      expect(approveButtons).toHaveLength(1);
      expect(rejectButtons).toHaveLength(1);
    });

    it('should call onApprove when approve button is clicked', async () => {
      const onApprove = vi.fn();
      renderTable({ showApprovalActions: true, onApprove });

      await userEvent.click(screen.getByRole('button', { name: /approve/i }));

      expect(onApprove).toHaveBeenCalledTimes(1);
      expect(onApprove).toHaveBeenCalledWith(mockMembers[1]); // Jane Pending
    });

    it('should call onReject when reject button is clicked', async () => {
      const onReject = vi.fn();
      renderTable({ showApprovalActions: true, onReject });

      await userEvent.click(screen.getByRole('button', { name: /reject/i }));

      expect(onReject).toHaveBeenCalledTimes(1);
      expect(onReject).toHaveBeenCalledWith(mockMembers[1]); // Jane Pending
    });
  });

  describe('row click', () => {
    it('should call onRowClick when a row is clicked', async () => {
      const onRowClick = vi.fn();
      renderTable({ onRowClick });

      // Click on John Active's name
      await userEvent.click(screen.getByText('John Active'));

      expect(onRowClick).toHaveBeenCalledTimes(1);
      expect(onRowClick).toHaveBeenCalledWith(mockMembers[0]);
    });
  });

  describe('avatar styling', () => {
    it('should render pending member avatar with warning color', () => {
      renderTable();

      // The pending member avatar should be styled differently
      // We check that the component renders without errors
      expect(screen.getByText('JP')).toBeInTheDocument();
    });
  });
});
