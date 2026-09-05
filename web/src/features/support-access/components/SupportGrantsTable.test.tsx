import '@/lib/i18n';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { SupportGrantsTable } from './SupportGrantsTable';
import type { SupportGrant } from '../types';

const activeGrant: SupportGrant = {
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

const historyGrant: SupportGrant = {
  id: 'grant-past',
  grantedRole: 'ward_admin',
  purpose: 'Ward 4 heat scores stuck after the bulk import',
  status: 'revoked',
  grantedBy: 'admin-1',
  grantedByName: 'Thandi Mokoena',
  grantedAt: '2026-08-28T14:02:00Z',
  expiresAt: '2026-08-28T15:02:00Z',
  lastActivity: '2026-08-28T14:20:00Z',
  revokedAt: '2026-08-28T14:35:00Z',
  expiredAt: null,
};

describe('SupportGrantsTable', () => {
  it('should render the last activity placeholder when the grant has no activity yet', () => {
    render(
      <SupportGrantsTable
        activeGrants={[activeGrant]}
        historyGrants={[]}
        onRevoke={vi.fn()}
      />
    );

    expect(screen.getByText('Never')).toBeInTheDocument();
  });

  it('should not render a revoke action in the history tab', () => {
    render(
      <SupportGrantsTable
        activeGrants={[]}
        historyGrants={[historyGrant]}
        onRevoke={vi.fn()}
      />
    );

    fireEvent.click(screen.getByRole('tab', { name: /history/i }));

    expect(screen.queryByRole('button', { name: /revoke/i })).not.toBeInTheDocument();
  });

  it('should call onRevoke with the grant when the revoke action is pressed', () => {
    const onRevoke = vi.fn();
    render(
      <SupportGrantsTable
        activeGrants={[activeGrant]}
        historyGrants={[]}
        onRevoke={onRevoke}
      />
    );

    fireEvent.click(screen.getByRole('button', { name: /revoke/i }));

    expect(onRevoke).toHaveBeenCalledWith(activeGrant);
  });
});
