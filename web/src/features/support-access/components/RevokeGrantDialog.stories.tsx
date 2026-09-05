import type { Meta, StoryObj } from '@storybook/react-vite';

import { RevokeGrantDialog } from './RevokeGrantDialog';
import type { SupportGrant } from '../types';

const grant: SupportGrant = {
  id: 'grant-1',
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

const meta = {
  title: 'Features/SupportAccess/RevokeGrantDialog',
  component: RevokeGrantDialog,
  args: {
    open: true,
    grant,
    onClose: () => {},
    onConfirm: () => {},
    isLoading: false,
  },
} satisfies Meta<typeof RevokeGrantDialog>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const Loading: Story = {
  args: { isLoading: true },
};
