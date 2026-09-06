import type { ReactElement } from 'react';
import type { Decorator, Meta, StoryObj } from '@storybook/react-vite';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import { DashboardLayout } from './DashboardLayout';
import { podSettingsKeys } from '@/features/pod-settings/hooks';
import type { PodSettings } from '@/features/pod-settings/types';
import type { AdminUser } from '@/features/auth/types';

const podChief: AdminUser = {
  id: 'admin-1',
  email: 'chief@ward42.example.com',
  displayName: 'Thandi Mokoena',
  sectorId: null,
  role: 'pod_chief',
};

const sectorAdmin: AdminUser = {
  id: 'admin-2',
  email: 'sectoradmin1@ward42.example.com',
  displayName: 'Sipho Nkosi',
  sectorId: 'sector-1',
  role: 'sector_admin',
};

function withAuthAndPodSettings(admin: AdminUser, podSettings?: PodSettings): Decorator {
  return (Story): ReactElement => {
    localStorage.setItem('accessToken', 'storybook-token');
    localStorage.setItem('admin', JSON.stringify(admin));

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
    if (podSettings) {
      queryClient.setQueryData(podSettingsKeys.all, podSettings);
    }

    return (
      <QueryClientProvider client={queryClient}>
        <Story />
      </QueryClientProvider>
    );
  };
}

const meta = {
  title: 'Templates/DashboardLayout/HeaderStates',
  component: DashboardLayout,
  args: {
    children: <div>Page content</div>,
  },
} satisfies Meta<typeof DashboardLayout>;

export default meta;
type Story = StoryObj<typeof meta>;

export const PodChiefWithLogo: Story = {
  decorators: [
    withAuthAndPodSettings(podChief, {
      name: 'Ward42',
      displayName: 'Munserv Pod Ward42',
      logoUrl: 'https://cdn.ward42.org.za/branding/pod-logo.png',
    }),
  ],
};

export const PodChiefWithoutLogo: Story = {
  decorators: [
    withAuthAndPodSettings(podChief, {
      name: 'Ward42',
      displayName: 'Munserv Pod Ward42',
      logoUrl: null,
    }),
  ],
};

export const SectorAdminDefault: Story = {
  decorators: [withAuthAndPodSettings(sectorAdmin)],
};
