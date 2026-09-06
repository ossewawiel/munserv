import type { ReactElement } from 'react';
import type { Decorator, Meta, StoryObj } from '@storybook/react-vite';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import { PodSettingsPage } from './PodSettingsPage';
import { podSettingsKeys } from './hooks';
import type { PodSettings } from './types';
import type { AdminUser } from '@/features/auth/types';

const podChief: AdminUser = {
  id: 'admin-1',
  email: 'chief@ward42.example.com',
  displayName: 'Thandi Mokoena',
  sectorId: null,
  role: 'pod_chief',
};

const podSettings: PodSettings = {
  name: 'Ward42',
  displayName: 'Munserv Pod Ward42',
  // A local asset, not a remote URL: nothing outside the harness can fetch a
  // real pod-logo URL, so the baseline would show a broken-image glyph.
  logoUrl: '/assets/app-mark.png',
};

function withAuthAndPodSettings(): Decorator {
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
    queryClient.setQueryData(podSettingsKeys.all, podSettings);

    return (
      <QueryClientProvider client={queryClient}>
        <Story />
      </QueryClientProvider>
    );
  };
}

const meta = {
  title: 'Pages/PodSettings/PodSettingsPage',
  component: PodSettingsPage,
} satisfies Meta<typeof PodSettingsPage>;

export default meta;
type Story = StoryObj<typeof meta>;

// Matches Main.dc.html: pod identity, the pod and ward boundary placeholder
// cards side by side, and Support access. usePodSetup's mock data always
// returns one ward, which is the variant drawn on this artboard.
export const Main: Story = {
  decorators: [withAuthAndPodSettings()],
};
