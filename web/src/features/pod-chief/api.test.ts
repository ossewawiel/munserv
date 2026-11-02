import { describe, it, expect, vi, beforeEach } from 'vitest';

import { apiClient } from '@/lib/api-client';
import { podChiefApi } from './api';

vi.mock('@/lib/api-client', () => ({
  apiClient: { get: vi.fn() },
}));

const getMock = vi.mocked(apiClient.get);

describe('podChiefApi.listAdministrators', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    getMock.mockResolvedValue({ data: { items: [], total: 0 } });
  });

  it('should request the plain path when the query is empty', async () => {
    await podChiefApi.listAdministrators();

    expect(getMock).toHaveBeenCalledWith('/pod/administrators');
  });

  it('should serialise sort as column and direction', async () => {
    await podChiefApi.listAdministrators({ sort: { column: 'displayName', direction: 'desc' } });

    expect(getMock).toHaveBeenCalledWith('/pod/administrators?sort=displayName%3Adesc');
  });

  it('should repeat the role parameter for each role', async () => {
    await podChiefApi.listAdministrators({ roles: ['ward_chief', 'sector_admin'], wardId: 'w1' });

    expect(getMock).toHaveBeenCalledWith(
      '/pod/administrators?role=ward_chief&role=sector_admin&wardId=w1'
    );
  });

  it('should omit a blank search term', async () => {
    await podChiefApi.listAdministrators({ q: '' });

    expect(getMock).toHaveBeenCalledWith('/pod/administrators');
  });
});
