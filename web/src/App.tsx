import { Routes, Route, Navigate } from 'react-router-dom';

import { ProtectedRoute } from '@/components/guards/ProtectedRoute';
import { RoleGuard } from '@/components/guards/RoleGuard';
import { AdminManagementPage } from '@/features/admin-management/AdminManagementPage';
import { LoginPage } from '@/features/auth/LoginPage';
import { RegisterPage } from '@/features/auth/RegisterPage';
import { DashboardPage } from '@/features/dashboard/DashboardPage';
import { HeatReportPage } from '@/features/dashboard/HeatReportPage';
import { GroundAdminsPage } from '@/features/ground-admins/GroundAdminsPage';
import { IssuesPage } from '@/features/issues/IssuesPage';
import { IssueMapPage } from '@/features/issues/IssueMapPage';
import { IssueDetailPage } from '@/features/issues/IssueDetailPage';
import { MembersPage } from '@/features/members/MembersPage';
import { MessagesPage } from '@/features/messages/MessagesPage';
import { SectorSettingsPage } from '@/features/sector-settings/SectorSettingsPage';

function App() {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      {/* Protected routes */}
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <DashboardPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/issues"
        element={
          <ProtectedRoute>
            <IssuesPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/issues/map"
        element={
          <ProtectedRoute>
            <IssueMapPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/issues/:id"
        element={
          <ProtectedRoute>
            <IssueDetailPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/reports/heat"
        element={
          <ProtectedRoute>
            <HeatReportPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/members"
        element={
          <ProtectedRoute>
            <MembersPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/messages"
        element={
          <ProtectedRoute>
            <MessagesPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/messages/:id"
        element={
          <ProtectedRoute>
            <MessagesPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/ground-admins"
        element={
          <ProtectedRoute>
            <GroundAdminsPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/admin-management"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="sector_chief">
              <AdminManagementPage />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/settings/sector"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="sector_chief">
              <SectorSettingsPage />
            </RoleGuard>
          </ProtectedRoute>
        }
      />

      {/* Catch-all redirect */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
