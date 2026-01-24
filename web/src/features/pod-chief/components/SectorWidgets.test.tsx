import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

import { SectorWidgets } from './SectorWidgets';
import type { SectorDashboardStats } from '../types';

// Mock react-i18next
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'podChief.dashboard.totalIssues': 'Total Issues',
        'podChief.dashboard.openIssues': 'Open Issues',
        'podChief.dashboard.resolvedThisMonth': 'Resolved This Month',
        'podChief.dashboard.activeGroundAdmins': 'Active Ground Admins',
        'podChief.dashboard.totalMembers': 'Total Members',
      };
      return translations[key] ?? key;
    },
  }),
}));

const mockStats: SectorDashboardStats = {
  sectorId: 'sector-1',
  sectorName: 'Sector A',
  totalIssues: 30,
  openIssues: 10,
  resolvedThisMonth: 8,
  activeGroundAdmins: 2,
  totalMembers: 150,
};

describe('SectorWidgets', () => {
  it('renders loading skeletons when isLoading is true', () => {
    render(<SectorWidgets stats={undefined} isLoading />);

    // Should show 5 skeleton cards
    const skeletons = document.querySelectorAll('.MuiSkeleton-root');
    expect(skeletons.length).toBe(5);
  });

  it('renders loading skeletons when stats is undefined', () => {
    render(<SectorWidgets stats={undefined} />);

    const skeletons = document.querySelectorAll('.MuiSkeleton-root');
    expect(skeletons.length).toBe(5);
  });

  it('renders all stat cards with correct labels', () => {
    render(<SectorWidgets stats={mockStats} />);

    expect(screen.getByText('Total Issues')).toBeInTheDocument();
    expect(screen.getByText('Open Issues')).toBeInTheDocument();
    expect(screen.getByText('Resolved This Month')).toBeInTheDocument();
    expect(screen.getByText('Active Ground Admins')).toBeInTheDocument();
    expect(screen.getByText('Total Members')).toBeInTheDocument();
  });

  it('renders all stat values correctly', () => {
    render(<SectorWidgets stats={mockStats} />);

    expect(screen.getByText('30')).toBeInTheDocument(); // totalIssues
    expect(screen.getByText('10')).toBeInTheDocument(); // openIssues
    expect(screen.getByText('8')).toBeInTheDocument(); // resolvedThisMonth
    expect(screen.getByText('2')).toBeInTheDocument(); // activeGroundAdmins
    expect(screen.getByText('150')).toBeInTheDocument(); // totalMembers
  });

  it('renders zero values correctly', () => {
    const zeroStats: SectorDashboardStats = {
      sectorId: 'sector-1',
      sectorName: 'Empty Sector',
      totalIssues: 0,
      openIssues: 0,
      resolvedThisMonth: 0,
      activeGroundAdmins: 0,
      totalMembers: 0,
    };

    render(<SectorWidgets stats={zeroStats} />);

    // All zeros should be rendered
    const zeros = screen.getAllByText('0');
    expect(zeros.length).toBe(5);
  });
});
