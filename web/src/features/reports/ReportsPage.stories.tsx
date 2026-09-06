import type { ReactElement } from 'react';
import type { Decorator, Meta, StoryObj } from '@storybook/react-vite';
import { Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import type { AdminUser } from '@/features/auth/types';
import { ReportsPage } from './ReportsPage';

const podChief: AdminUser = {
  id: 'admin-1',
  email: 'chief@ward42.example.com',
  displayName: 'Thandi Mokoena',
  sectorId: null,
  role: 'pod_chief',
};

const WARD_ID = '550e8400-e29b-41d4-a716-446655440030';

function withAuth(): Decorator {
  return (Story): ReactElement => {
    localStorage.setItem('accessToken', 'storybook-token');
    localStorage.setItem('admin', JSON.stringify(podChief));

    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          staleTime: Infinity,
          refetchOnMount: false,
          refetchOnWindowFocus: false,
        },
      },
    });

    return (
      <QueryClientProvider client={queryClient}>
        <Story />
      </QueryClientProvider>
    );
  };
}

const meta = {
  title: 'Features/Reports/ReportsPage',
  component: ReportsPage,
} satisfies Meta<typeof ReportsPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const General: Story = {
  args: { scope: 'pod' },
  parameters: { router: { initialEntries: ['/reports/general'] } },
  decorators: [withAuth()],
  render: () => (
    <Routes>
      <Route path="/reports/general" element={<ReportsPage scope="pod" />} />
    </Routes>
  ),
};

export const WardScope: Story = {
  args: { scope: 'ward' },
  parameters: { router: { initialEntries: [`/reports/ward/${WARD_ID}?tab=issues`] } },
  decorators: [withAuth()],
  render: () => (
    <Routes>
      <Route path="/reports/ward/:wardId" element={<ReportsPage scope="ward" />} />
    </Routes>
  ),
};
