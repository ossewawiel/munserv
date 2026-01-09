import { http, HttpResponse } from 'msw';

// Default mock data
const mockIssues = [
  {
    id: 'issue-1',
    sectorId: 'sector-1',
    type: 'pothole',
    state: 'reported',
    location: { lat: -26.2041, lng: 28.0473 },
    heat: 45,
    reportedAt: new Date().toISOString(),
  },
];

const mockMembers = [
  {
    id: 'member-1',
    displayName: 'Test Member',
    phone: '+27123456789',
    status: 'active',
  },
];

const mockDashboardStats = {
  totalIssues: 150,
  openIssues: 45,
  resolvedThisWeek: 12,
  avgResolutionDays: 3.5,
  issuesByType: {
    pothole: 30,
    water_leak: 25,
    street_light: 20,
    other: 25,
  },
  issuesByState: {
    reported: 20,
    confirmed: 15,
    in_progress: 10,
    fixed: 100,
    rejected: 5,
  },
};

export const handlers = [
  // Auth
  http.post('*/auth/admin/login', async ({ request }) => {
    const body = await request.json() as { email: string; password: string };
    if (body.email === 'admin@ward42.example.com' && body.password === 'admin123') {
      return HttpResponse.json({
        tokens: {
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token',
        },
        profile: {
          admin: {
            id: 'admin-1',
            email: body.email,
            displayName: 'Test Admin',
            sectorId: 'sector-1',
            role: 'SECTOR_ADMIN',
          },
          sector: {
            id: 'sector-1',
            name: 'Ward 42',
            center: { lat: -26.2041, lng: 28.0473 },
          },
        },
      });
    }
    return HttpResponse.json({ message: 'Invalid credentials' }, { status: 401 });
  }),

  // Issues
  http.get('*/issues', ({ request }) => {
    const url = new URL(request.url);
    const page = Number(url.searchParams.get('page') || 1);
    const limit = Number(url.searchParams.get('limit') || 20);

    return HttpResponse.json({
      items: mockIssues,
      total: mockIssues.length,
      page,
      limit,
    });
  }),

  http.get('*/issues/:id', ({ params }) => {
    const issue = mockIssues.find((i) => i.id === params.id);
    if (issue) {
      return HttpResponse.json(issue);
    }
    return HttpResponse.json({ message: 'Issue not found' }, { status: 404 });
  }),

  http.patch('*/issues/:id/state', async ({ params, request }) => {
    const body = await request.json() as { state: string };
    const issue = mockIssues.find((i) => i.id === params.id);
    if (issue) {
      return HttpResponse.json({ ...issue, state: body.state });
    }
    return HttpResponse.json({ message: 'Issue not found' }, { status: 404 });
  }),

  // Members
  http.get('*/admin/members', ({ request }) => {
    const url = new URL(request.url);
    const page = Number(url.searchParams.get('page') || 1);
    const limit = Number(url.searchParams.get('limit') || 20);

    return HttpResponse.json({
      items: mockMembers,
      total: mockMembers.length,
      page,
      limit,
    });
  }),

  // Dashboard
  http.get('*/admin/dashboard', () => {
    return HttpResponse.json(mockDashboardStats);
  }),

  http.get('*/admin/reports/heat', ({ request }) => {
    const url = new URL(request.url);
    const limit = Number(url.searchParams.get('limit') || 10);

    return HttpResponse.json({
      items: mockIssues.slice(0, limit).map((issue, index) => ({
        ...issue,
        rank: index + 1,
      })),
    });
  }),

  // Sectors
  http.get('*/sectors', () => {
    return HttpResponse.json({
      items: [
        { id: 'sector-1', name: 'Ward 42', center: { lat: -26.2041, lng: 28.0473 } },
        { id: 'sector-2', name: 'Ward 43', center: { lat: -26.2100, lng: 28.0500 } },
      ],
    });
  }),

  // Member Registration
  http.post('*/auth/register/web', async ({ request }) => {
    const body = (await request.json()) as {
      email: string;
      firstName: string;
      surname: string;
      phone: string;
      address: string;
      latitude: number;
      longitude: number;
      sectorId: string;
    };

    // Simulate email already exists error
    if (body.email === 'existing@example.com') {
      return HttpResponse.json(
        { message: 'Email already registered' },
        { status: 409 }
      );
    }

    // Simulate validation error
    if (!body.email || !body.firstName || !body.surname) {
      return HttpResponse.json(
        { message: 'Validation failed' },
        { status: 400 }
      );
    }

    return HttpResponse.json(
      {
        message: 'Registration submitted successfully',
        memberId: 'member-new-1',
      },
      { status: 201 }
    );
  }),
];
