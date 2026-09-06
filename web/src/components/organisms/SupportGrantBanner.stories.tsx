import type { Meta, StoryObj } from '@storybook/react-vite';
import { http, HttpResponse } from 'msw';

import { worker } from '@/test/mocks/browser';
import type { SupportGrant } from '@/features/support-access/types';
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

// The banner refetches GET /support-access/grants/current on mount; without an
// override the browser MSW worker answers with the shared mockCurrentSupportGrant,
// whose expiresAt does not match the frozen clock above and rewrites the countdown
// text mid-capture. Each story pins the same grant it stored, or the 403 an
// expired/revoked grant token actually gets (see specs/contracts/api.md).
function pinCurrentGrant(expiresAtMs: number): void {
  worker.resetHandlers();
  worker.use(
    http.get('*/support-access/grants/current', () => {
      const grant: SupportGrant = {
        id: 'grant-1',
        grantedRole: 'pod_admin',
        purpose: 'Storybook fixture',
        status: 'active',
        grantedBy: 'admin-1',
        grantedByName: 'Thandi Mokoena',
        grantedAt: new Date(expiresAtMs - 60 * 60 * 1000).toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        lastActivity: null,
        revokedAt: null,
        expiredAt: null,
      };
      return HttpResponse.json(grant);
    })
  );
}

function pinExpiredCurrentGrant(): void {
  worker.resetHandlers();
  worker.use(http.get('*/support-access/grants/current', () => new HttpResponse(null, { status: 403 })));
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
    pinCurrentGrant(GRANT_EXPIRES_AT);
    return <SupportGrantBanner />;
  },
};

export const Expiring: Story = {
  render: () => {
    withStoredGrant(GRANT_EXPIRES_AT - (4 * 60 + 38) * 1000, GRANT_EXPIRES_AT); // 04:38 left
    pinCurrentGrant(GRANT_EXPIRES_AT);
    return <SupportGrantBanner />;
  },
};

export const Expired: Story = {
  render: () => {
    withStoredGrant(GRANT_EXPIRES_AT + 1000, GRANT_EXPIRES_AT);
    pinExpiredCurrentGrant();
    return <SupportGrantBanner />;
  },
};
