import type { Meta, StoryObj } from '@storybook/react-vite';

import { SupportGrantBanner } from './SupportGrantBanner';

const SUPPORT_GRANT_KEY = 'supportGrant';

// The banner counts down from Date.now(); freeze the clock so every capture renders the same digits.
// Matches the artboards: the grant on the support-access canvas expires at 10:58:00 UTC.
const FROZEN_NOW = Date.parse('2026-09-05T10:10:48Z');
const GRANT_EXPIRES_AT = Date.parse('2026-09-05T10:58:00Z');

function withStoredGrant(nowMs: number, expiresAtMs: number) {
  Date.now = () => nowMs;
  localStorage.setItem('accessToken', 'story-access-token');
  localStorage.setItem(
    SUPPORT_GRANT_KEY,
    JSON.stringify({
      grantId: 'grant-1',
      grantedRole: 'pod_admin',
      expiresAt: new Date(expiresAtMs).toISOString(),
    })
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
    withStoredGrant(FROZEN_NOW, GRANT_EXPIRES_AT); // 47:12 left
    return <SupportGrantBanner />;
  },
};

export const Expiring: Story = {
  render: () => {
    withStoredGrant(GRANT_EXPIRES_AT - (4 * 60 + 38) * 1000, GRANT_EXPIRES_AT); // 04:38 left
    return <SupportGrantBanner />;
  },
};

export const Expired: Story = {
  render: () => {
    withStoredGrant(GRANT_EXPIRES_AT + 1000, GRANT_EXPIRES_AT);
    return <SupportGrantBanner />;
  },
};
