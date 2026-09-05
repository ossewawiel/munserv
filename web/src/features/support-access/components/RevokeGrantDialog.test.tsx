import '@/lib/i18n';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { RevokeGrantDialog } from './RevokeGrantDialog';
import type { SupportGrant } from '../types';

const grant: SupportGrant = {
  id: 'grant-active',
  grantedRole: 'pod_admin',
  purpose: 'Investigate duplicate issue reports in sector 3',
  status: 'active',
  grantedBy: 'admin-1',
  grantedByName: 'Thandi Mokoena',
  grantedAt: '2026-09-05T09:41:00Z',
  expiresAt: '2026-09-05T10:41:00Z',
  lastActivity: null,
  revokedAt: null,
  expiredAt: null,
};

describe('RevokeGrantDialog', () => {
  it('should name the granted role in the confirmation', () => {
    render(
      <RevokeGrantDialog
        open
        grant={grant}
        onClose={vi.fn()}
        onConfirm={vi.fn()}
        isLoading={false}
      />
    );

    expect(screen.getByText(/Pod Admin/)).toBeInTheDocument();
  });

  it('should call onConfirm when the pod chief confirms', () => {
    const onConfirm = vi.fn();
    render(
      <RevokeGrantDialog
        open
        grant={grant}
        onClose={vi.fn()}
        onConfirm={onConfirm}
        isLoading={false}
      />
    );

    fireEvent.click(screen.getByRole('button', { name: /revoke access/i }));

    expect(onConfirm).toHaveBeenCalled();
  });
});
