import type { Meta, StoryObj } from '@storybook/react-vite';

import { SupportGrantBanner } from './SupportGrantBanner';

const SUPPORT_GRANT_KEY = 'supportGrant';

function withStoredGrant(expiresAt: string) {
  localStorage.setItem('accessToken', 'story-access-token');
  localStorage.setItem(
    SUPPORT_GRANT_KEY,
    JSON.stringify({ grantId: 'grant-1', grantedRole: 'pod_admin', expiresAt })
  );
}

const meta = {
  title: 'Organisms/SupportGrantBanner',
  component: SupportGrantBanner,
} satisfies Meta<typeof SupportGrantBanner>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Active: Story = {
  render: () => {
    withStoredGrant(new Date(Date.now() + 47 * 60 * 1000).toISOString());
    return <SupportGrantBanner />;
  },
};

export const Expiring: Story = {
  render: () => {
    withStoredGrant(new Date(Date.now() + 4 * 60 * 1000).toISOString());
    return <SupportGrantBanner />;
  },
};

export const Expired: Story = {
  render: () => {
    withStoredGrant(new Date(Date.now() - 1000).toISOString());
    return <SupportGrantBanner />;
  },
};
