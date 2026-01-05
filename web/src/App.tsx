import { Routes, Route, Navigate } from 'react-router-dom';

import { ProtectedRoute } from '@/components/guards/ProtectedRoute';
import { LoginPage } from '@/features/auth/LoginPage';
import { DashboardPage } from '@/features/dashboard/DashboardPage';
import { IssuesPage } from '@/features/issues/IssuesPage';
import { IssueDetailPage } from '@/features/issues/IssueDetailPage';

function HeatReportPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Heat Report</h1>
      <p className="text-text-muted">Heat Report Page (Placeholder)</p>
    </div>
  );
}

function MembersPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Members</h1>
      <p className="text-text-muted">Members List Page (Placeholder)</p>
    </div>
  );
}

function App() {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={<LoginPage />} />

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

      {/* Catch-all redirect */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
