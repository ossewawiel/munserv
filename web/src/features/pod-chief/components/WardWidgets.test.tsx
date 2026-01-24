import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

import { WardWidgets } from './WardWidgets';
import type { WardDashboardStats } from '../types';

// Mock react-i18next
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'podChief.dashboard.totalIssues': 'Total Issues',
        'podChief.dashboard.openIssues': 'Open Issues',
        'podChief.dashboard.resolvedThisMonth': 'Resolved This Month',
        'podChief.dashboard.activeGroundAdmins': 'Active Ground Admins',
        'podChief.dashboard.sectors': 'Sectors',
      };
      return translations[key] ?? key;
    },
  }),
}));

const mockStats: WardDashboardStats = {
  wardId: 'ward-1',
  wardName: 'Ward 1',
  totalIssues: 75,
  openIssues: 20,
  resolvedThisMonth: 15,
  sectorCount: 4,
  activeGroundAdmins: 3,
};

describe('WardWidgets', () => {
  it('renders loading skeletons when isLoading is true', () => {
    render(<WardWidgets stats={undefined} isLoading />);

    // Should show 5 skeleton cards
    const skeletons = document.querySelectorAll('.MuiSkeleton-root');
    expect(skeletons.length).toBe(5);
  });

  it('renders loading skeletons when stats is undefined', () => {
    render(<WardWidgets stats={undefined} />);

    const skeletons = document.querySelectorAll('.MuiSkeleton-root');
    expect(skeletons.length).toBe(5);
  });

  it('renders all stat cards with correct labels', () => {
    render(<WardWidgets stats={mockStats} />);

    expect(screen.getByText('Total Issues')).toBeInTheDocument();
    expect(screen.getByText('Open Issues')).toBeInTheDocument();
    expect(screen.getByText('Resolved This Month')).toBeInTheDocument();
    expect(screen.getByText('Active Ground Admins')).toBeInTheDocument();
    expect(screen.getByText('Sectors')).toBeInTheDocument();
  });

  it('renders all stat values correctly', () => {
    render(<WardWidgets stats={mockStats} />);

    expect(screen.getByText('75')).toBeInTheDocument(); // totalIssues
    expect(screen.getByText('20')).toBeInTheDocument(); // openIssues
    expect(screen.getByText('15')).toBeInTheDocument(); // resolvedThisMonth
    expect(screen.getByText('3')).toBeInTheDocument(); // activeGroundAdmins
    expect(screen.getByText('4')).toBeInTheDocument(); // sectorCount
  });

  it('renders zero values correctly', () => {
    const zeroStats: WardDashboardStats = {
      wardId: 'ward-1',
      wardName: 'Empty Ward',
      totalIssues: 0,
      openIssues: 0,
      resolvedThisMonth: 0,
      sectorCount: 0,
      activeGroundAdmins: 0,
    };

    render(<WardWidgets stats={zeroStats} />);

    // All zeros should be rendered
    const zeros = screen.getAllByText('0');
    expect(zeros.length).toBe(5);
  });
});
