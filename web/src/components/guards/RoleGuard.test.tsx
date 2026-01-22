import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { RoleGuard } from './RoleGuard';
import type { AdminRole } from '@/shared/types/admin';

// Mock useAuth hook
const mockHasPermission = vi.fn<(role: AdminRole) => boolean>();

vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => ({
    hasPermission: mockHasPermission,
  }),
}));

function renderWithRouter(
  requiredRole: AdminRole,
  fallback = '/',
) {
  return render(
    <MemoryRouter initialEntries={['/protected']}>
      <Routes>
        <Route
          path="/protected"
          element={
            <RoleGuard requiredRole={requiredRole} fallback={fallback}>
              <div data-testid="protected-content">Protected Content</div>
            </RoleGuard>
          }
        />
        <Route path="/" element={<div data-testid="home">Home Page</div>} />
        <Route path="/custom-fallback" element={<div data-testid="custom-fallback">Custom Fallback</div>} />
      </Routes>
    </MemoryRouter>
  );
}

describe('RoleGuard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should render children when user has required permission', () => {
    mockHasPermission.mockReturnValue(true);

    renderWithRouter('sector_chief');

    expect(screen.getByTestId('protected-content')).toBeInTheDocument();
    expect(mockHasPermission).toHaveBeenCalledWith('sector_chief');
  });

  it('should redirect to default fallback when user lacks permission', () => {
    mockHasPermission.mockReturnValue(false);

    renderWithRouter('sector_chief');

    expect(screen.queryByTestId('protected-content')).not.toBeInTheDocument();
    expect(screen.getByTestId('home')).toBeInTheDocument();
  });

  it('should redirect to custom fallback when specified', () => {
    mockHasPermission.mockReturnValue(false);

    renderWithRouter('sector_chief', '/custom-fallback');

    expect(screen.queryByTestId('protected-content')).not.toBeInTheDocument();
    expect(screen.getByTestId('custom-fallback')).toBeInTheDocument();
  });

  it('should allow sector_admin to access sector_admin routes', () => {
    mockHasPermission.mockReturnValue(true);

    renderWithRouter('sector_admin');

    expect(screen.getByTestId('protected-content')).toBeInTheDocument();
    expect(mockHasPermission).toHaveBeenCalledWith('sector_admin');
  });

  it('should allow pod_chief to access sector_chief routes (higher permission)', () => {
    mockHasPermission.mockReturnValue(true);

    renderWithRouter('sector_chief');

    expect(screen.getByTestId('protected-content')).toBeInTheDocument();
  });

  it('should deny sector_admin access to sector_chief routes', () => {
    mockHasPermission.mockReturnValue(false);

    renderWithRouter('sector_chief');

    expect(screen.queryByTestId('protected-content')).not.toBeInTheDocument();
    expect(screen.getByTestId('home')).toBeInTheDocument();
  });
});
