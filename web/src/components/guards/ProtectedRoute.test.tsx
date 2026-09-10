import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { ProtectedRoute } from './ProtectedRoute';
import type { AdminUser } from '@/features/auth/types';

const mockUseAuth = vi.fn<() => { isAuthenticated: boolean; admin: AdminUser | null }>();

vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => mockUseAuth(),
}));

const createPodAdmin = (onboardingStatus: string | null): AdminUser => ({
  id: 'admin-1',
  email: 'pod.admin@ward42.example.com',
  displayName: 'Pod Administrator',
  sectorId: null,
  role: 'pod_admin',
  onboardingStatus,
});

function renderProtectedRoute(admin: AdminUser | null) {
  mockUseAuth.mockReturnValue({ isAuthenticated: true, admin });

  return render(
    <MemoryRouter initialEntries={['/']}>
      <Routes>
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <div data-testid="dashboard">Dashboard</div>
            </ProtectedRoute>
          }
        />
        <Route
          path="/onboarding/change-password"
          element={<div data-testid="change-password">Change Password</div>}
        />
        <Route
          path="/onboarding/complete-profile"
          element={<div data-testid="complete-profile">Complete Profile</div>}
        />
      </Routes>
    </MemoryRouter>
  );
}

describe('ProtectedRoute', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should send a pending pod administrator to the change password page', () => {
    renderProtectedRoute(createPodAdmin('pending'));

    expect(screen.getByTestId('change-password')).toBeInTheDocument();
    expect(screen.queryByTestId('dashboard')).not.toBeInTheDocument();
  });

  it('should send a password-changed pod administrator to the complete profile page', () => {
    renderProtectedRoute(createPodAdmin('password_changed'));

    expect(screen.getByTestId('complete-profile')).toBeInTheDocument();
    expect(screen.queryByTestId('dashboard')).not.toBeInTheDocument();
  });

  it('should render the dashboard for an active pod administrator', () => {
    renderProtectedRoute(createPodAdmin('active'));

    expect(screen.getByTestId('dashboard')).toBeInTheDocument();
  });
});
