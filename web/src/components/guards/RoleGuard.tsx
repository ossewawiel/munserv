import { type FC, type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from '@/shared/hooks/useAuth';
import type { AdminRole } from '@/shared/types/admin';

interface RoleGuardProps {
  /** The minimum role required to access the children */
  requiredRole: AdminRole;
  /** Content to render if the user has sufficient permissions */
  children: ReactNode;
  /** Path to redirect to if the user doesn't have permission (default: '/') */
  fallback?: string;
}

/**
 * Guards content based on the user's role.
 * Redirects to fallback path if user doesn't have the required role.
 * Must be used inside a ProtectedRoute to ensure user is authenticated.
 */
export const RoleGuard: FC<RoleGuardProps> = ({
  requiredRole,
  children,
  fallback = '/',
}) => {
  const { hasPermission } = useAuth();

  if (!hasPermission(requiredRole)) {
    return <Navigate to={fallback} replace />;
  }

  return <>{children}</>;
};
