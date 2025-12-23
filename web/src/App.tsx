import { Routes, Route, Navigate } from 'react-router-dom';

// Placeholder pages - to be implemented
function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-md w-96">
        <h1 className="text-2xl font-bold text-center mb-6">MunServ Admin</h1>
        <p className="text-gray-600 text-center">Login Page (Placeholder)</p>
      </div>
    </div>
  );
}

function DashboardPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      <p className="text-gray-600">Dashboard Page (Placeholder)</p>
    </div>
  );
}

function IssuesPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Issues</h1>
      <p className="text-gray-600">Issues List Page (Placeholder)</p>
    </div>
  );
}

function IssueDetailPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Issue Details</h1>
      <p className="text-gray-600">Issue Detail Page (Placeholder)</p>
    </div>
  );
}

function HeatReportPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Heat Report</h1>
      <p className="text-gray-600">Heat Report Page (Placeholder)</p>
    </div>
  );
}

function MembersPage() {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Members</h1>
      <p className="text-gray-600">Members List Page (Placeholder)</p>
    </div>
  );
}

function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/" element={<DashboardPage />} />
      <Route path="/issues" element={<IssuesPage />} />
      <Route path="/issues/:id" element={<IssueDetailPage />} />
      <Route path="/reports/heat" element={<HeatReportPage />} />
      <Route path="/members" element={<MembersPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
