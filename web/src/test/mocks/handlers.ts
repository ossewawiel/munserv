import { http, HttpResponse } from 'msw';
import type { Message, MessageStatus, MessageType } from '@/shared/types/message';
import type { GroundAdmin, GroundAdminStatus } from '@/shared/types/groundAdmin';
import type { IssueVerification, VerificationStatus } from '@/shared/types/verification';
import type { SectorSettings, VerificationMode } from '@/shared/types/sectorSettings';
import type { Admin, AdminCreatedResponse } from '@/features/admin-management/types';
import type { SupportGrant } from '@/features/support-access/types';

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
    firstName: 'John',
    surname: 'Active',
    email: 'john@example.com',
    phoneNumber: '+27123456789',
    address: '123 Main Street',
    status: 'active',
    issueCount: 5,
    joinedAt: '2024-01-15T10:00:00Z',
    // Ground Admin: Active
    isGroundAdmin: true,
    groundAdminStatus: 'active',
    hasPendingApplication: false,
    hasInvitationPending: false,
  },
  {
    id: 'member-2',
    firstName: 'Jane',
    surname: 'Pending',
    email: 'jane@example.com',
    phoneNumber: '+27987654321',
    address: '456 Oak Avenue',
    status: 'pending_approval',
    issueCount: 0,
    joinedAt: '2024-03-01T14:30:00Z',
    // Not a Ground Admin (pending member approval)
    isGroundAdmin: false,
    hasPendingApplication: false,
    hasInvitationPending: false,
  },
  {
    id: 'member-3',
    firstName: 'Bob',
    surname: 'Suspended',
    email: 'bob@example.com',
    phoneNumber: '+27111222333',
    address: '789 Pine Lane',
    status: 'suspended',
    issueCount: 2,
    joinedAt: '2023-06-20T09:15:00Z',
    // Not a Ground Admin (suspended)
    isGroundAdmin: false,
    hasPendingApplication: false,
    hasInvitationPending: false,
  },
  {
    id: 'member-4',
    firstName: 'Alice',
    surname: 'Regular',
    email: 'alice@example.com',
    phoneNumber: '+27444555666',
    address: '321 Elm Street',
    status: 'active',
    issueCount: 12,
    joinedAt: '2023-08-10T11:20:00Z',
    // Regular member - can be invited
    isGroundAdmin: false,
    hasPendingApplication: false,
    hasInvitationPending: false,
  },
  {
    id: 'member-5',
    firstName: 'Charlie',
    surname: 'Applied',
    email: 'charlie@example.com',
    phoneNumber: '+27777888999',
    address: '555 Maple Drive',
    status: 'active',
    issueCount: 8,
    joinedAt: '2023-09-05T16:45:00Z',
    // Has pending GA application
    isGroundAdmin: false,
    hasPendingApplication: true,
    hasInvitationPending: false,
    pendingApplicationId: 'app-apply-1',
  },
  {
    id: 'member-6',
    firstName: 'Diana',
    surname: 'Invited',
    email: 'diana@example.com',
    phoneNumber: '+27111000222',
    address: '777 Cedar Court',
    status: 'active',
    issueCount: 15,
    joinedAt: '2023-07-20T08:30:00Z',
    // Was invited, pending response
    isGroundAdmin: false,
    hasPendingApplication: false,
    hasInvitationPending: true,
    pendingApplicationId: 'app-inv-1',
  },
  {
    id: 'member-7',
    firstName: 'Edward',
    surname: 'OnHold',
    email: 'edward@example.com',
    phoneNumber: '+27333444555',
    address: '999 Oak Boulevard',
    status: 'active',
    issueCount: 3,
    joinedAt: '2023-05-15T13:00:00Z',
    // Ground Admin on hold
    isGroundAdmin: true,
    groundAdminStatus: 'on_hold',
    hasPendingApplication: false,
    hasInvitationPending: false,
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

// =============================================
// MESSAGES MOCK DATA
// =============================================
export const mockMessages: Message[] = [
  {
    id: 'msg-1',
    type: 'ground_admin_application' as MessageType,
    title: 'Ground Admin Application',
    body: 'John Smith has applied to become a Ground Admin in your sector.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    senderId: 'member-1',
    senderType: 'member',
    status: 'unread' as MessageStatus,
    actionType: 'approve_reject',
    relatedEntityId: 'member-1',
    relatedEntityType: 'member',
    metadata: { memberSince: '2024-01-15', issuesReported: 47 },
    createdAt: '2026-01-19T10:00:00Z',
  },
  {
    id: 'msg-2',
    type: 'verify_new_issue' as MessageType,
    title: 'Verify New Issue',
    body: 'A new pothole has been reported at 123 Main Street. Please verify this issue exists.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    senderType: 'system',
    status: 'unread' as MessageStatus,
    actionType: 'confirm_verify',
    relatedEntityId: 'issue-1',
    relatedEntityType: 'issue',
    createdAt: '2026-01-19T09:30:00Z',
  },
  {
    id: 'msg-3',
    type: 'monthly_report' as MessageType,
    title: 'Monthly Report - January 2026',
    body: 'Your sector resolved 45 issues this month. View the full report for details.',
    recipientId: 'admin-1',
    recipientType: 'admin',
    senderType: 'system',
    status: 'read' as MessageStatus,
    actionType: 'view',
    createdAt: '2026-01-15T08:00:00Z',
    readAt: '2026-01-15T09:00:00Z',
  },
  {
    id: 'msg-4',
    type: 'ground_admin_approved' as MessageType,
    title: 'Ground Admin Status Approved',
    body: 'Your application to become a Ground Admin has been approved.',
    recipientId: 'member-1',
    recipientType: 'member',
    senderType: 'system',
    status: 'actioned' as MessageStatus,
    actionType: 'acknowledge',
    actionResult: 'acknowledged',
    createdAt: '2026-01-10T14:00:00Z',
    readAt: '2026-01-10T14:30:00Z',
    actionedAt: '2026-01-10T14:30:00Z',
  },
];

// =============================================
// GROUND ADMINS MOCK DATA
// =============================================
export const mockGroundAdmins: GroundAdmin[] = [
  {
    id: 'ga-1',
    memberId: 'member-1',
    name: 'John Smith',
    status: 'active' as GroundAdminStatus,
    since: '2025-06-15T00:00:00Z',
    responseRate: 92,
    pendingVerifications: 2,
  },
  {
    id: 'ga-2',
    memberId: 'member-4',
    name: 'Sarah Johnson',
    status: 'active' as GroundAdminStatus,
    since: '2025-08-20T00:00:00Z',
    responseRate: 85,
    pendingVerifications: 1,
  },
  {
    id: 'ga-3',
    memberId: 'member-5',
    name: 'Mike Wilson',
    status: 'on_hold' as GroundAdminStatus,
    since: '2025-04-10T00:00:00Z',
    responseRate: 45,
    pendingVerifications: 0,
  },
  {
    id: 'ga-4',
    memberId: 'member-6',
    name: 'Emily Brown',
    status: 'inactive' as GroundAdminStatus,
    since: '2024-12-01T00:00:00Z',
    responseRate: 78,
    pendingVerifications: 0,
  },
];

// =============================================
// VERIFICATION MOCK DATA
// =============================================
export const mockVerifications: IssueVerification[] = [
  {
    id: 'ver-1',
    issueId: 'issue-1',
    verificationType: 'existence',
    assignedTo: 'member-1',
    assignedToName: 'John Smith',
    verifiedBy: 'member-1',
    verifiedByName: 'John Smith',
    result: 'confirmed',
    requestedAt: '2026-01-15T10:00:00Z',
    respondedAt: '2026-01-15T11:30:00Z',
    status: 'completed' as VerificationStatus,
  },
  {
    id: 'ver-2',
    issueId: 'issue-1',
    verificationType: 'fix',
    assignedToName: 'Sarah Johnson',
    requestedAt: '2026-01-18T14:00:00Z',
    status: 'pending' as VerificationStatus,
  },
  {
    id: 'ver-3',
    issueId: 'issue-2',
    verificationType: 'existence',
    result: 'cannot_verify',
    reason: 'wrong_location',
    note: 'The GPS coordinates seem to be off by about 500m.',
    verifiedBy: 'member-4',
    verifiedByName: 'Sarah Johnson',
    requestedAt: '2026-01-10T09:00:00Z',
    respondedAt: '2026-01-10T16:00:00Z',
    status: 'completed' as VerificationStatus,
  },
];

// =============================================
// SECTOR SETTINGS MOCK DATA
// =============================================
export const mockSectorSettings: SectorSettings = {
  id: 'settings-1',
  sectorId: 'sector-1',
  newIssueVerificationMode: 'all_notified' as VerificationMode,
  fixVerificationMode: 'admin_assigns' as VerificationMode,
  daysFixedBeforeClosed: 7,
  minimumGroundAdmins: 3,
  createdAt: '2025-01-01T00:00:00Z',
  updatedAt: '2026-01-15T10:00:00Z',
};

// =============================================
// ADMIN MANAGEMENT MOCK DATA
// =============================================
export const mockAdmins: Admin[] = [
  {
    id: 'admin-2',
    email: 'sectoradmin1@ward42.example.com',
    displayName: 'Sector Admin One',
    role: 'sector_admin',
    sectorId: 'sector-1',
    createdAt: '2025-06-15T10:00:00Z',
    deletedAt: null,
  },
  {
    id: 'admin-3',
    email: 'sectoradmin2@ward42.example.com',
    displayName: 'Sector Admin Two',
    role: 'sector_admin',
    sectorId: 'sector-1',
    createdAt: '2025-08-20T14:30:00Z',
    deletedAt: null,
  },
];

// =============================================
// SUPPORT ACCESS MOCK DATA
// =============================================
export const mockSupportGrants: SupportGrant[] = [
  {
    id: 'grant-1',
    grantedRole: 'pod_admin',
    purpose: 'Investigate duplicate issue reports in sector 3',
    status: 'expired',
    grantedBy: 'admin-1',
    grantedByName: 'Thandi Mokoena',
    grantedAt: '2026-08-20T09:41:00Z',
    expiresAt: '2026-08-20T10:41:00Z',
    lastActivity: '2026-08-20T10:10:00Z',
    revokedAt: null,
    expiredAt: '2026-08-20T10:41:00Z',
  },
];

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
    const status = url.searchParams.get('status');
    const isGroundAdmin = url.searchParams.get('isGroundAdmin');
    const hasPendingApplication = url.searchParams.get('hasPendingApplication');
    const hasInvitationPending = url.searchParams.get('hasInvitationPending');

    let filteredMembers = mockMembers;

    if (status) {
      filteredMembers = filteredMembers.filter((m) => m.status === status);
    }
    if (isGroundAdmin === 'true') {
      filteredMembers = filteredMembers.filter((m) => m.isGroundAdmin);
    }
    if (hasPendingApplication === 'true') {
      filteredMembers = filteredMembers.filter((m) => m.hasPendingApplication);
    }
    if (hasInvitationPending === 'true') {
      filteredMembers = filteredMembers.filter((m) => m.hasInvitationPending);
    }

    return HttpResponse.json({
      items: filteredMembers,
      pagination: {
        page,
        limit,
        totalItems: filteredMembers.length,
        totalPages: Math.ceil(filteredMembers.length / limit),
      },
    });
  }),

  // Member pending count
  http.get('*/admin/members/pending-count', () => {
    const pendingCount = mockMembers.filter(
      (m) => m.status === 'pending_approval'
    ).length;
    return HttpResponse.json({ count: pendingCount });
  }),

  // Approve member
  http.post('*/admin/members/:id/approve', ({ params }) => {
    const member = mockMembers.find((m) => m.id === params.id);
    if (!member) {
      return HttpResponse.json({ message: 'Member not found' }, { status: 404 });
    }
    if (member.status !== 'pending_approval') {
      return HttpResponse.json(
        { message: 'Member is not pending approval' },
        { status: 400 }
      );
    }
    return HttpResponse.json({
      memberId: member.id,
      email: member.email,
      message: 'Member approved successfully',
    });
  }),

  // Reject member
  http.delete('*/admin/members/:id', ({ params }) => {
    const member = mockMembers.find((m) => m.id === params.id);
    if (!member) {
      return HttpResponse.json({ message: 'Member not found' }, { status: 404 });
    }
    return new HttpResponse(null, { status: 204 });
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

  // =============================================
  // MESSAGES HANDLERS
  // =============================================

  // GET /messages - List messages
  http.get('*/messages', ({ request }) => {
    const url = new URL(request.url);
    const status = url.searchParams.get('status');
    const page = Number(url.searchParams.get('page') || 1);

    let filteredMessages = [...mockMessages];
    if (status) {
      filteredMessages = filteredMessages.filter((m) => m.status === status);
    }

    const unreadCount = mockMessages.filter((m) => m.status === 'unread').length;

    return HttpResponse.json({
      items: filteredMessages,
      total: filteredMessages.length,
      page,
      unreadCount,
    });
  }),

  // GET /messages/:id - Get single message
  http.get('*/messages/:id', ({ params }) => {
    const message = mockMessages.find((m) => m.id === params.id);
    if (message) {
      return HttpResponse.json(message);
    }
    return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
  }),

  // PATCH /messages/:id/read - Mark message as read
  http.patch('*/messages/:id/read', ({ params }) => {
    const message = mockMessages.find((m) => m.id === params.id);
    if (message) {
      return HttpResponse.json({
        ...message,
        status: 'read',
        readAt: new Date().toISOString(),
      });
    }
    return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
  }),

  // POST /messages/:id/action - Perform action on message
  http.post('*/messages/:id/action', async ({ params, request }) => {
    const body = (await request.json()) as { action: string; note?: string };
    const message = mockMessages.find((m) => m.id === params.id);
    if (!message) {
      return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
    }
    if (message.status === 'actioned') {
      return HttpResponse.json({ message: 'Message already actioned' }, { status: 409 });
    }
    return HttpResponse.json({
      ...message,
      status: 'actioned',
      actionResult: body.action,
      actionedAt: new Date().toISOString(),
    });
  }),

  // =============================================
  // GROUND ADMIN HANDLERS
  // =============================================

  // GET /sectors/:id/ground-admins - List Ground Admins in sector
  http.get('*/sectors/:sectorId/ground-admins', ({ request }) => {
    const url = new URL(request.url);
    const status = url.searchParams.get('status');

    let filteredAdmins = [...mockGroundAdmins];
    if (status) {
      filteredAdmins = filteredAdmins.filter((ga) => ga.status === status);
    }

    return HttpResponse.json({
      items: filteredAdmins,
      total: filteredAdmins.length,
    });
  }),

  // POST /members/:id/ground-admin/invite - Invite member to become Ground Admin
  http.post('*/members/:memberId/ground-admin/invite', async ({ params, request }) => {
    const body = (await request.json()) as { message?: string };
    void body; // silence unused variable
    const memberId = params.memberId as string;

    // Check if already a ground admin
    const isGroundAdmin = mockGroundAdmins.some((ga) => ga.memberId === memberId);
    if (isGroundAdmin) {
      return HttpResponse.json(
        { message: 'Member is already a Ground Admin' },
        { status: 409 }
      );
    }

    return HttpResponse.json({
      applicationId: `app-${Date.now()}`,
      status: 'pending',
    });
  }),

  // POST /members/:id/ground-admin/approve - Approve Ground Admin application
  http.post('*/members/:memberId/ground-admin/approve', async ({ params, request }) => {
    const body = (await request.json()) as { applicationId: string };
    void body; // silence unused variable
    const memberId = params.memberId as string;

    return HttpResponse.json({
      status: 'approved',
      member: {
        id: memberId,
        name: 'Test Member',
        isGroundAdmin: true,
        groundAdminStatus: 'active',
      },
    });
  }),

  // POST /members/:id/ground-admin/decline - Decline Ground Admin application
  http.post('*/members/:memberId/ground-admin/decline', async ({ request }) => {
    const body = (await request.json()) as { applicationId: string; reason: string };
    void body; // silence unused variable

    return HttpResponse.json({
      status: 'declined',
    });
  }),

  // POST /members/:id/ground-admin/revoke - Revoke Ground Admin status
  http.post('*/members/:memberId/ground-admin/revoke', async ({ params, request }) => {
    const body = (await request.json()) as { reason: string };
    void body; // silence unused variable
    const memberId = params.memberId as string;

    const groundAdmin = mockGroundAdmins.find((ga) => ga.memberId === memberId);
    if (!groundAdmin) {
      return HttpResponse.json(
        { message: 'Member is not a Ground Admin' },
        { status: 409 }
      );
    }

    return HttpResponse.json({
      status: 'revoked',
      member: {
        id: memberId,
        name: groundAdmin.name,
        isGroundAdmin: false,
      },
    });
  }),

  // PATCH /members/:id/ground-admin/status - Update Ground Admin status
  http.patch('*/members/:memberId/ground-admin/status', async ({ params, request }) => {
    const body = (await request.json()) as { status: 'active' | 'on_hold' };
    const memberId = params.memberId as string;

    const groundAdmin = mockGroundAdmins.find((ga) => ga.memberId === memberId);
    if (!groundAdmin) {
      return HttpResponse.json(
        { message: 'Member is not a Ground Admin' },
        { status: 409 }
      );
    }

    return HttpResponse.json({
      ...groundAdmin,
      status: body.status,
    });
  }),

  // DELETE /members/:id/ground-admin/invite/:applicationId - Revoke pending Ground Admin invitation
  http.delete('*/members/:memberId/ground-admin/invite/:applicationId', () => {
    return HttpResponse.json({ status: 'revoked' });
  }),

  // =============================================
  // VERIFICATION HANDLERS
  // =============================================

  // POST /issues/:id/request-verification - Request verification for an issue
  http.post('*/issues/:issueId/request-verification', async ({ params, request }) => {
    const body = (await request.json()) as {
      type: 'existence' | 'fix';
      assignTo?: string;
      message?: string;
    };
    const issueId = params.issueId as string;

    const newVerification: IssueVerification = {
      id: `ver-${Date.now()}`,
      issueId,
      verificationType: body.type,
      assignedTo: body.assignTo,
      assignedToName: body.assignTo ? 'Assigned Ground Admin' : undefined,
      requestedAt: new Date().toISOString(),
      status: 'pending',
    };

    return HttpResponse.json(newVerification);
  }),

  // GET /issues/:id/verifications - Get verification history for issue
  http.get('*/issues/:issueId/verifications', ({ params }) => {
    const issueId = params.issueId as string;
    const verifications = mockVerifications.filter((v) => v.issueId === issueId);

    return HttpResponse.json({
      items: verifications,
    });
  }),

  // =============================================
  // SECTOR SETTINGS HANDLERS
  // =============================================

  // GET /sectors/:id/settings - Get sector settings
  http.get('*/sectors/:sectorId/settings', ({ params }) => {
    const sectorId = params.sectorId as string;

    if (sectorId !== mockSectorSettings.sectorId) {
      // Return default settings for any sector
      return HttpResponse.json({
        ...mockSectorSettings,
        id: `settings-${sectorId}`,
        sectorId,
      });
    }

    return HttpResponse.json(mockSectorSettings);
  }),

  // PATCH /sectors/:id/settings - Update sector settings
  http.patch('*/sectors/:sectorId/settings', async ({ params, request }) => {
    const body = (await request.json()) as {
      newIssueVerificationMode?: string;
      fixVerificationMode?: string;
      daysFixedBeforeClosed?: number;
      minimumGroundAdmins?: number;
    };
    const sectorId = params.sectorId as string;

    // Validate daysFixedBeforeClosed range
    if (
      body.daysFixedBeforeClosed !== undefined &&
      (body.daysFixedBeforeClosed < 1 || body.daysFixedBeforeClosed > 90)
    ) {
      return HttpResponse.json(
        { message: 'daysFixedBeforeClosed must be between 1 and 90' },
        { status: 400 }
      );
    }

    // Validate minimumGroundAdmins range
    if (
      body.minimumGroundAdmins !== undefined &&
      (body.minimumGroundAdmins < 0 || body.minimumGroundAdmins > 50)
    ) {
      return HttpResponse.json(
        { message: 'minimumGroundAdmins must be between 0 and 50' },
        { status: 400 }
      );
    }

    return HttpResponse.json({
      ...mockSectorSettings,
      sectorId,
      ...body,
      updatedAt: new Date().toISOString(),
    });
  }),

  // =============================================
  // ADMIN MANAGEMENT HANDLERS
  // =============================================

  // GET /admins - List admins in sector
  http.get('*/admins', () => {
    return HttpResponse.json({
      items: mockAdmins,
      total: mockAdmins.length,
    });
  }),

  // GET /admins/:id - Get single admin
  http.get('*/admins/:id', ({ params }) => {
    const admin = mockAdmins.find((a) => a.id === params.id);
    if (admin) {
      return HttpResponse.json(admin);
    }
    return HttpResponse.json({ message: 'Admin not found' }, { status: 404 });
  }),

  // POST /admins - Create new admin
  http.post('*/admins', async ({ request }) => {
    const body = (await request.json()) as {
      email: string;
      displayName: string;
      role: string;
    };

    // Check if email already exists
    if (mockAdmins.some((a) => a.email === body.email)) {
      return HttpResponse.json(
        { message: 'Email already exists' },
        { status: 409 }
      );
    }

    const newAdmin: AdminCreatedResponse = {
      id: `admin-${Date.now()}`,
      email: body.email,
      displayName: body.displayName,
      role: 'sector_admin',
      sectorId: 'sector-1',
      createdAt: new Date().toISOString(),
      deletedAt: null,
      temporaryPassword: 'TempPass123!',
    };

    return HttpResponse.json(newAdmin, { status: 201 });
  }),

  // PATCH /admins/:id - Update admin
  http.patch('*/admins/:id', async ({ params, request }) => {
    const body = (await request.json()) as { displayName?: string };
    const admin = mockAdmins.find((a) => a.id === params.id);

    if (!admin) {
      return HttpResponse.json({ message: 'Admin not found' }, { status: 404 });
    }

    return HttpResponse.json({
      ...admin,
      displayName: body.displayName ?? admin.displayName,
    });
  }),

  // DELETE /admins/:id - Delete admin
  http.delete('*/admins/:id', ({ params }) => {
    const admin = mockAdmins.find((a) => a.id === params.id);

    if (!admin) {
      return HttpResponse.json({ message: 'Admin not found' }, { status: 404 });
    }

    return new HttpResponse(null, { status: 204 });
  }),

  // =============================================
  // SUPPORT ACCESS HANDLERS
  // =============================================

  // GET /support-access/grants - List support grants, optionally filtered by status
  http.get('*/support-access/grants', ({ request }) => {
    const url = new URL(request.url);
    const status = url.searchParams.get('status');
    const items = status
      ? mockSupportGrants.filter((grant) => grant.status === status)
      : mockSupportGrants;

    return HttpResponse.json({
      items,
      total: items.length,
    });
  }),

  // POST /support-access/grants - Grant support access to the super user
  http.post('*/support-access/grants', async ({ request }) => {
    const body = (await request.json()) as { grantedRole: string; purpose: string };

    if (mockSupportGrants.some((grant) => grant.status === 'active')) {
      return HttpResponse.json(
        { code: 'active_grant_exists', message: 'An active grant already exists' },
        { status: 409 }
      );
    }

    const newGrant: SupportGrant = {
      id: `grant-${Date.now()}`,
      grantedRole: body.grantedRole as SupportGrant['grantedRole'],
      purpose: body.purpose,
      status: 'active',
      grantedBy: 'admin-1',
      grantedByName: 'Test Admin',
      grantedAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
      lastActivity: null,
      revokedAt: null,
      expiredAt: null,
    };

    return HttpResponse.json(newGrant, { status: 201 });
  }),
];
