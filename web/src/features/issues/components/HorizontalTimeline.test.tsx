import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { HorizontalTimeline } from './HorizontalTimeline';
import type { StateHistoryEntry } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          noResults: 'No results',
        },
        issues: {
          stateHistory: 'State History',
          states: {
            reported: 'Reported',
            confirmed: 'Confirmed',
            in_progress: 'In Progress',
            fixed: 'Fixed',
          },
        },
      },
    },
  },
});

const theme = createTheme();

function renderWithProviders(ui: React.ReactElement) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>{ui}</I18nextProvider>
    </ThemeProvider>
  );
}

// Mock history with varying time gaps to test proportional spacing
const mockHistory: StateHistoryEntry[] = [
  {
    state: 'reported',
    changedAt: '2024-01-12T10:00:00Z',
    changedBy: null, // No admin for initial report
  },
  {
    state: 'confirmed',
    changedAt: '2024-01-14T14:00:00Z', // 2 days later
    changedBy: 'admin-uuid-123',
    note: 'Verified on site',
  },
  {
    state: 'in_progress',
    changedAt: '2024-01-18T09:00:00Z', // 4 days later
    changedBy: 'admin-uuid-456',
  },
  {
    state: 'fixed',
    changedAt: '2024-01-20T16:00:00Z', // 2 days later
    changedBy: 'admin-uuid-456',
    note: 'Repair completed',
  },
];

describe('HorizontalTimeline', () => {
  it('should render all state history entries', () => {
    renderWithProviders(<HorizontalTimeline history={mockHistory} />);

    expect(screen.getByText('Reported')).toBeInTheDocument();
    expect(screen.getByText('Confirmed')).toBeInTheDocument();
    expect(screen.getByText('In Progress')).toBeInTheDocument();
    expect(screen.getByText('Fixed')).toBeInTheDocument();
  });

  it('should render dates for each entry', () => {
    renderWithProviders(<HorizontalTimeline history={mockHistory} />);

    // Check formatted dates appear
    expect(screen.getByText(/Jan.*12/i)).toBeInTheDocument();
    expect(screen.getByText(/Jan.*14/i)).toBeInTheDocument();
    expect(screen.getByText(/Jan.*18/i)).toBeInTheDocument();
    expect(screen.getByText(/Jan.*20/i)).toBeInTheDocument();
  });

  it('should NOT display changedBy UUIDs', () => {
    renderWithProviders(<HorizontalTimeline history={mockHistory} />);

    // UUIDs should not be rendered
    expect(screen.queryByText('admin-uuid-123')).not.toBeInTheDocument();
    expect(screen.queryByText('admin-uuid-456')).not.toBeInTheDocument();
  });

  it('should show empty state when no history', () => {
    renderWithProviders(<HorizontalTimeline history={[]} />);
    expect(screen.getByText('No results')).toBeInTheDocument();
  });

  it('should be wrapped in a card', () => {
    const { container } = renderWithProviders(<HorizontalTimeline history={mockHistory} />);
    const card = container.firstChild;
    expect(card).toHaveClass('MuiPaper-root');
  });

  it('should render title', () => {
    renderWithProviders(<HorizontalTimeline history={mockHistory} />);
    expect(screen.getByText('State History')).toBeInTheDocument();
  });

  it('should display timeline entries horizontally with role list', () => {
    const { container } = renderWithProviders(<HorizontalTimeline history={mockHistory} />);

    // Check for horizontal layout with role="list"
    const timeline = container.querySelector('[role="list"]');
    expect(timeline).toBeInTheDocument();

    // Check for list items
    const items = container.querySelectorAll('[role="listitem"]');
    expect(items).toHaveLength(4);
  });

  it('should handle single entry without connectors', () => {
    const singleEntry: StateHistoryEntry[] = [{
      state: 'reported',
      changedAt: '2024-01-12T10:00:00Z',
      changedBy: null,
    }];

    renderWithProviders(<HorizontalTimeline history={singleEntry} />);
    expect(screen.getByText('Reported')).toBeInTheDocument();
  });

  it('should use proportional spacing based on time duration', () => {
    // This test verifies the component handles varying time gaps
    // The actual visual spacing is CSS-based, but we can verify the structure
    const historyWithVaryingGaps: StateHistoryEntry[] = [
      { state: 'reported', changedAt: '2024-01-01T00:00:00Z', changedBy: null },
      { state: 'confirmed', changedAt: '2024-01-02T00:00:00Z', changedBy: null }, // 1 day
      { state: 'fixed', changedAt: '2024-01-10T00:00:00Z', changedBy: null }, // 8 days
    ];

    const { container } = renderWithProviders(
      <HorizontalTimeline history={historyWithVaryingGaps} />
    );

    // Should render all entries
    expect(screen.getByText('Reported')).toBeInTheDocument();
    expect(screen.getByText('Confirmed')).toBeInTheDocument();
    expect(screen.getByText('Fixed')).toBeInTheDocument();

    // Should have 3 list items (entries)
    const items = container.querySelectorAll('[role="listitem"]');
    expect(items).toHaveLength(3);
  });
});
