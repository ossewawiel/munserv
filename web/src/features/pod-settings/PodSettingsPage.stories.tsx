import { useEffect, type FC, type ReactElement, type ReactNode } from 'react';
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

const AuthSeed: FC<{ children: ReactNode }> = ({ children }) => {
  // useAuth reads localStorage synchronously (no effect of its own), so the
  // seed has to happen during render, before DashboardLayout's first read -
  // an effect would run too late and the page would render once, wrongly,
  // with no admin. The cleanup effect below removes the seed on unmount so
  // it never leaks into the next story or a real session in the same tab.
  localStorage.setItem('accessToken', 'storybook-token');
  localStorage.setItem('admin', JSON.stringify(podChief));

  useEffect(() => {
    return () => {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('admin');
    };
  }, []);

  return <>{children}</>;
};

function withAuthAndPodSettings(): Decorator {
  return (Story): ReactElement => {
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
      <AuthSeed>
        <QueryClientProvider client={queryClient}>
          <Story />
        </QueryClientProvider>
      </AuthSeed>
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
