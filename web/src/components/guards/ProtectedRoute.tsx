import { type FC, type ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';

import { useAuth } from '@/shared/hooks/useAuth';

interface ProtectedRouteProps {
  children: ReactNode;
}

export const ProtectedRoute: FC<ProtectedRouteProps> = ({ children }) => {
  const { isAuthenticated, admin } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) {
    // Redirect to login, saving the attempted URL for redirect after login
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Check onboarding status - redirect if not complete
  if (admin?.onboardingStatus === 'pending') {
    return <Navigate to="/onboarding/change-password" replace />;
  }

  if (admin?.onboardingStatus === 'password_changed') {
    return <Navigate to="/onboarding/complete-profile" replace />;
  }

  return <>{children}</>;
};
