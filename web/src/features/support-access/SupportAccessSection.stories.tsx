import type { ReactElement } from 'react';
import type { Decorator, Meta, StoryObj } from '@storybook/react-vite';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { userEvent, within } from 'storybook/test';

import { SupportAccessSection } from './SupportAccessSection';
import type { SupportGrant, SupportGrantListResponse } from './types';

const activeGrant: SupportGrant = {
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

const historyGrants: SupportGrant[] = [
  {
    id: 'grant-2',
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
    id: 'grant-3',
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

function withQueryData(response: SupportGrantListResponse): Decorator {
  return (Story): ReactElement => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: { retry: false, staleTime: Infinity, refetchOnMount: false, refetchOnWindowFocus: false },
        mutations: { retry: false },
      },
    });
    queryClient.setQueryData(['support-grants', 'all'], response);

    return (
      <QueryClientProvider client={queryClient}>
        <Story />
      </QueryClientProvider>
    );
  };
}

const meta = {
  title: 'Features/SupportAccess/SupportAccessSection',
  component: SupportAccessSection,
} satisfies Meta<typeof SupportAccessSection>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Empty: Story = {
  decorators: [withQueryData({ items: [], total: 0 })],
};

export const ActiveGrant: Story = {
  decorators: [withQueryData({ items: [activeGrant], total: 1 })],
};

export const GrantsHistory: Story = {
  decorators: [withQueryData({ items: [activeGrant, ...historyGrants], total: 3 })],
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    await userEvent.click(canvas.getByRole('tab', { name: /history/i }));
  },
};
