import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useIssuesForMap } from './hooks';
import type { ReactNode } from 'react';

// Mock useAuth hook
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => ({
    admin: {
      id: 'admin-1',
      email: 'admin@ward42.example.com',
      displayName: 'Test Admin',
      sectorId: 'sector-1',
      role: 'SECTOR_ADMIN',
    },
    isAuthenticated: true,
  }),
}));

const mockMapIssues = [
  {
    id: 'issue-1',
    type: 'pothole',
    state: 'reported',
    location: { latitude: -26.2041, longitude: 28.0473 },
    heat: 45,
    thumbnailUrl: '/uploads/issue-1.jpg',
    createdAt: '2024-01-15T10:00:00Z',
  },
  {
    id: 'issue-2',
    type: 'water_leak',
    state: 'confirmed',
    location: { latitude: -26.2050, longitude: 28.0480 },
    heat: 72,
    thumbnailUrl: '/uploads/issue-2.jpg',
    createdAt: '2024-01-16T11:00:00Z',
  },
  {
    id: 'issue-3',
    type: 'street_light',
    state: 'in_progress',
    location: { latitude: -26.2060, longitude: 28.0490 },
    heat: 30,
    thumbnailUrl: '/uploads/issue-3.jpg',
    createdAt: '2024-01-17T12:00:00Z',
  },
];

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

function createWrapper() {
  const queryClient = createTestQueryClient();
  return function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );
  };
}

describe('issues hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useIssuesForMap', () => {
    it('should fetch all issues for map successfully', async () => {
      server.use(
        http.get('*/issues', ({ request }) => {
          const url = new URL(request.url);
          const limit = url.searchParams.get('limit');
          // Verify limit is set for map view (max 100 per backend constraint)
          expect(Number(limit)).toBe(100);
          return HttpResponse.json({
            items: mockMapIssues,
            pagination: {
              page: 1,
              limit: 100,
              totalItems: mockMapIssues.length,
              totalPages: 1,
            },
          });
        })
      );

      const { result } = renderHook(() => useIssuesForMap(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toHaveLength(3);
      expect(result.current.data?.[0].id).toBe('issue-1');
    });

    it('should return loading state initially', () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json({
            items: mockMapIssues,
            pagination: {
              page: 1,
              limit: 100,
              totalItems: mockMapIssues.length,
              totalPages: 1,
            },
          });
        })
      );

      const { result } = renderHook(() => useIssuesForMap(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json(
            { message: 'Server error' },
            { status: 500 }
          );
        })
      );

      const { result } = renderHook(() => useIssuesForMap(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should return empty array when no issues exist', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json({
            items: [],
            pagination: {
              page: 1,
              limit: 100,
              totalItems: 0,
              totalPages: 0,
            },
          });
        })
      );

      const { result } = renderHook(() => useIssuesForMap(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toEqual([]);
    });

    it('should have issues with correct location data', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json({
            items: mockMapIssues,
            pagination: {
              page: 1,
              limit: 100,
              totalItems: mockMapIssues.length,
              totalPages: 1,
            },
          });
        })
      );

      const { result } = renderHook(() => useIssuesForMap(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      // Verify all issues have location data needed for map pins
      result.current.data?.forEach((issue) => {
        expect(issue.location).toBeDefined();
        expect(issue.location.latitude).toBeDefined();
        expect(issue.location.longitude).toBeDefined();
        expect(issue.type).toBeDefined();
        expect(issue.state).toBeDefined();
        expect(issue.heat).toBeDefined();
      });
    });

    it('should use query key for caching', async () => {
      const queryClient = createTestQueryClient();

      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json({
            items: mockMapIssues,
            pagination: {
              page: 1,
              limit: 100,
              totalItems: mockMapIssues.length,
              totalPages: 1,
            },
          });
        })
      );

      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      const { result } = renderHook(() => useIssuesForMap(), { wrapper });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      // Check query cache has the data with expected key
      const cachedData = queryClient.getQueryData(['issues', 'map']);
      expect(cachedData).toEqual(mockMapIssues);
    });
  });
});
