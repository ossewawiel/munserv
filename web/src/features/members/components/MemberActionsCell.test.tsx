import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { MemberActionsCell } from './MemberActionsCell';
import type { MemberListItem } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        members: {
          approve: 'Approve',
          reject: 'Reject',
          revokeInvite: 'Revoke Invitation',
        },
        groundAdmin: {
          invite: 'Invite',
          review: 'Review',
          manage: 'Manage',
        },
      },
    },
  },
});

const theme = createTheme();

const createMember = (overrides: Partial<MemberListItem> = {}): MemberListItem => ({
  id: '1',
  firstName: 'John',
  surname: 'Doe',
  email: 'john@example.com',
  phoneNumber: '+27123456789',
  address: '123 Main St',
  status: 'active',
  issueCount: 5,
  joinedAt: '2025-01-01T00:00:00Z',
  isGroundAdmin: false,
  ...overrides,
});

const defaultProps = {
  onApprove: vi.fn(),
  onReject: vi.fn(),
  onInvite: vi.fn(),
  onReviewApplication: vi.fn(),
  onManage: vi.fn(),
  onRevokeInvite: vi.fn(),
};

function renderComponent(member: MemberListItem, props = defaultProps) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <MemberActionsCell member={member} {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
}

describe('MemberActionsCell', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should show approve/reject for pending_approval members', () => {
    const member = createMember({ status: 'pending_approval' });
    renderComponent(member);

    expect(screen.getByLabelText(/approve/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/reject/i)).toBeInTheDocument();
  });

  it('should show manage for Ground Admins', () => {
    const member = createMember({ isGroundAdmin: true, groundAdminStatus: 'active' });
    renderComponent(member);

    expect(screen.getByLabelText(/manage/i)).toBeInTheDocument();
  });

  it('should show revoke for pending invitations', () => {
    const member = createMember({
      hasInvitationPending: true,
      pendingApplicationId: 'app-1',
    });
    renderComponent(member);

    expect(screen.getByLabelText(/revoke/i)).toBeInTheDocument();
  });

  it('should show review for pending applications', () => {
    const member = createMember({ hasPendingApplication: true });
    renderComponent(member);

    expect(screen.getByLabelText(/review/i)).toBeInTheDocument();
  });

  it('should show invite for active members with issues', () => {
    const member = createMember({ status: 'active', issueCount: 5 });
    renderComponent(member);

    expect(screen.getByLabelText(/invite/i)).toBeInTheDocument();
  });

  it('should show nothing for active members with no issues', () => {
    const member = createMember({ status: 'active', issueCount: 0 });
    const { container } = renderComponent(member);

    expect(container.firstChild).toBeNull();
  });

  it('should call onApprove when approve clicked', async () => {
    const onApprove = vi.fn();
    const member = createMember({ status: 'pending_approval' });
    renderComponent(member, { ...defaultProps, onApprove });

    await fireEvent.click(screen.getByLabelText(/approve/i));
    expect(onApprove).toHaveBeenCalledWith(member);
  });

  it('should call onReject when reject clicked', async () => {
    const onReject = vi.fn();
    const member = createMember({ status: 'pending_approval' });
    renderComponent(member, { ...defaultProps, onReject });

    await fireEvent.click(screen.getByLabelText(/reject/i));
    expect(onReject).toHaveBeenCalledWith(member);
  });

  it('should call onInvite when invite clicked', async () => {
    const onInvite = vi.fn();
    const member = createMember({ status: 'active', issueCount: 5 });
    renderComponent(member, { ...defaultProps, onInvite });

    await fireEvent.click(screen.getByLabelText(/invite/i));
    expect(onInvite).toHaveBeenCalledWith(member);
  });

  it('should call onReviewApplication when review clicked', async () => {
    const onReviewApplication = vi.fn();
    const member = createMember({ hasPendingApplication: true });
    renderComponent(member, { ...defaultProps, onReviewApplication });

    await fireEvent.click(screen.getByLabelText(/review/i));
    expect(onReviewApplication).toHaveBeenCalledWith(member);
  });

  it('should call onManage when manage clicked', async () => {
    const onManage = vi.fn();
    const member = createMember({ isGroundAdmin: true, groundAdminStatus: 'active' });
    renderComponent(member, { ...defaultProps, onManage });

    await fireEvent.click(screen.getByLabelText(/manage/i));
    expect(onManage).toHaveBeenCalledWith(member);
  });

  it('should call onRevokeInvite when revoke clicked', async () => {
    const onRevokeInvite = vi.fn();
    const member = createMember({
      hasInvitationPending: true,
      pendingApplicationId: 'app-1',
    });
    renderComponent(member, { ...defaultProps, onRevokeInvite });

    await fireEvent.click(screen.getByLabelText(/revoke/i));
    expect(onRevokeInvite).toHaveBeenCalledWith(member);
  });

  describe('priority order', () => {
    it('should prioritize pending_approval over isGroundAdmin', () => {
      const member = createMember({
        status: 'pending_approval',
        isGroundAdmin: true,
      });
      renderComponent(member);

      expect(screen.getByLabelText(/approve/i)).toBeInTheDocument();
      expect(screen.queryByLabelText(/manage/i)).not.toBeInTheDocument();
    });

    it('should prioritize isGroundAdmin over hasInvitationPending', () => {
      const member = createMember({
        isGroundAdmin: true,
        hasInvitationPending: true,
      });
      renderComponent(member);

      expect(screen.getByLabelText(/manage/i)).toBeInTheDocument();
      expect(screen.queryByLabelText(/revoke/i)).not.toBeInTheDocument();
    });

    it('should prioritize hasInvitationPending over hasPendingApplication', () => {
      const member = createMember({
        hasInvitationPending: true,
        hasPendingApplication: true,
      });
      renderComponent(member);

      expect(screen.getByLabelText(/revoke/i)).toBeInTheDocument();
      expect(screen.queryByLabelText(/review/i)).not.toBeInTheDocument();
    });

    it('should prioritize hasPendingApplication over invite', () => {
      const member = createMember({
        status: 'active',
        issueCount: 5,
        hasPendingApplication: true,
      });
      renderComponent(member);

      expect(screen.getByLabelText(/review/i)).toBeInTheDocument();
      expect(screen.queryByLabelText(/invite/i)).not.toBeInTheDocument();
    });
  });
});
