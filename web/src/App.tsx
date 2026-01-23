import { type FC } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import { ProtectedRoute } from '@/components/guards/ProtectedRoute';
import { RoleGuard } from '@/components/guards/RoleGuard';
import { DashboardLayout } from '@/components/templates/DashboardLayout';
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

/** Placeholder page for features not yet implemented */
const PlaceholderPage: FC<{ title: string }> = ({ title }) => (
  <DashboardLayout>
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        {title}
      </Typography>
      <Typography variant="body1" color="text.secondary">
        This feature is coming soon.
      </Typography>
    </Box>
  </DashboardLayout>
);

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
      <Route
        path="/settings/ward"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="ward_chief">
              <PlaceholderPage title="Ward Settings" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/settings/pod"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_chief">
              <PlaceholderPage title="Pod Settings" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/pod-administrators"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_chief">
              <PlaceholderPage title="Pod Administrators" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/dashboard/ward/:wardId"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_admin">
              <PlaceholderPage title="Ward Dashboard" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/dashboard/sector/:sectorId"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_admin">
              <PlaceholderPage title="Sector Dashboard" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/reports/general"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_admin">
              <PlaceholderPage title="General Reports" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/reports/ward/:wardId"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_admin">
              <PlaceholderPage title="Ward Reports" />
            </RoleGuard>
          </ProtectedRoute>
        }
      />
      <Route
        path="/reports/sector/:sectorId"
        element={
          <ProtectedRoute>
            <RoleGuard requiredRole="pod_admin">
              <PlaceholderPage title="Sector Reports" />
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
