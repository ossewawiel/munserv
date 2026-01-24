import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

import { PodChiefWidgets } from './PodChiefWidgets';
import type { PodDashboardStats } from '../types';

// Mock react-i18next
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'podChief.dashboard.totalIssues': 'Total Issues',
        'podChief.dashboard.openIssues': 'Open Issues',
        'podChief.dashboard.resolvedThisMonth': 'Resolved This Month',
        'podChief.dashboard.pendingIssues': 'Pending Issues',
        'podChief.dashboard.activeAdmins': 'Active Administrators',
        'podChief.dashboard.totalMembers': 'Total Members',
        'podChief.dashboard.activeGroundAdmins': 'Active Ground Admins',
        'podChief.dashboard.wards': 'Wards',
        'podChief.dashboard.sectors': 'Sectors',
      };
      return translations[key] ?? key;
    },
  }),
}));

const mockStats: PodDashboardStats = {
  totalIssues: 150,
  openIssues: 45,
  resolvedThisMonth: 23,
  pendingIssues: 12,
  activeAdministrators: 5,
  totalMembers: 1250,
  activeGroundAdmins: 8,
  wardCount: 4,
  sectorCount: 16,
};

describe('PodChiefWidgets', () => {
  it('renders loading skeletons when isLoading is true', () => {
    render(<PodChiefWidgets stats={undefined} isLoading />);

    // Should show 8 skeleton cards
    const skeletons = document.querySelectorAll('.MuiSkeleton-root');
    expect(skeletons.length).toBe(8);
  });

  it('renders loading skeletons when stats is undefined', () => {
    render(<PodChiefWidgets stats={undefined} />);

    const skeletons = document.querySelectorAll('.MuiSkeleton-root');
    expect(skeletons.length).toBe(8);
  });

  it('renders all stat cards with correct labels', () => {
    render(<PodChiefWidgets stats={mockStats} />);

    expect(screen.getByText('Total Issues')).toBeInTheDocument();
    expect(screen.getByText('Open Issues')).toBeInTheDocument();
    expect(screen.getByText('Resolved This Month')).toBeInTheDocument();
    expect(screen.getByText('Pending Issues')).toBeInTheDocument();
    expect(screen.getByText('Active Administrators')).toBeInTheDocument();
    expect(screen.getByText('Total Members')).toBeInTheDocument();
    expect(screen.getByText('Active Ground Admins')).toBeInTheDocument();
    expect(screen.getByText('Wards')).toBeInTheDocument();
    expect(screen.getByText('Sectors')).toBeInTheDocument();
  });

  it('renders all stat values correctly', () => {
    render(<PodChiefWidgets stats={mockStats} />);

    expect(screen.getByText('150')).toBeInTheDocument(); // totalIssues
    expect(screen.getByText('45')).toBeInTheDocument(); // openIssues
    expect(screen.getByText('23')).toBeInTheDocument(); // resolvedThisMonth
    expect(screen.getByText('12')).toBeInTheDocument(); // pendingIssues
    expect(screen.getByText('5')).toBeInTheDocument(); // activeAdministrators
    expect(screen.getByText('1250')).toBeInTheDocument(); // totalMembers
    expect(screen.getByText('8')).toBeInTheDocument(); // activeGroundAdmins
    expect(screen.getByText('4')).toBeInTheDocument(); // wardCount
    expect(screen.getByText('16')).toBeInTheDocument(); // sectorCount
  });

  it('renders zero values correctly', () => {
    const zeroStats: PodDashboardStats = {
      totalIssues: 0,
      openIssues: 0,
      resolvedThisMonth: 0,
      pendingIssues: 0,
      activeAdministrators: 0,
      totalMembers: 0,
      activeGroundAdmins: 0,
      wardCount: 0,
      sectorCount: 0,
    };

    render(<PodChiefWidgets stats={zeroStats} />);

    // All zeros should be rendered
    const zeros = screen.getAllByText('0');
    expect(zeros.length).toBe(9);
  });
});
