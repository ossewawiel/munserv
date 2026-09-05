import type { Meta, StoryObj } from '@storybook/react-vite';

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
  expiresAt: '2026-09-05T10:58:00Z',
  lastActivity: '2026-09-05T09:58:00Z',
  revokedAt: null,
  expiredAt: null,
};

const historyGrants: SupportGrant[] = [
  {
    id: 'grant-1',
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
  },
  {
    id: 'grant-2',
    grantedRole: 'pod_admin',
    purpose: 'Photos on issue 2841 fail to upload from the mobile app',
    status: 'expired',
    grantedBy: 'admin-1',
    grantedByName: 'Thandi Mokoena',
    grantedAt: '2026-08-21T08:15:00Z',
    expiresAt: '2026-08-21T09:20:00Z',
    lastActivity: '2026-08-21T08:50:00Z',
    revokedAt: null,
    expiredAt: '2026-08-21T09:20:00Z',
  },
];

const meta = {
  title: 'Features/SupportAccess/SupportGrantsTable',
  component: SupportGrantsTable,
} satisfies Meta<typeof SupportGrantsTable>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Active: Story = {
  args: {
    variant: 'active',
    grants: [activeGrant],
    onRevoke: () => {},
  },
};

export const ActiveEmpty: Story = {
  args: {
    variant: 'active',
    grants: [],
    onRevoke: () => {},
  },
};

export const History: Story = {
  args: {
    variant: 'history',
    grants: historyGrants,
  },
};

export const HistoryEmpty: Story = {
  args: {
    variant: 'history',
    grants: [],
  },
};
