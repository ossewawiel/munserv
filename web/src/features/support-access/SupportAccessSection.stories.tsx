import type { ReactElement } from 'react';
import type { Decorator, Meta, StoryObj } from '@storybook/react-vite';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

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

function withQueryData(response: SupportGrantListResponse): Decorator {
  return (Story): ReactElement => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: { retry: false, staleTime: Infinity, refetchOnMount: false, refetchOnWindowFocus: false },
        mutations: { retry: false },
      },
    });
    queryClient.setQueryData(['support-grants', 'active'], response);

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
