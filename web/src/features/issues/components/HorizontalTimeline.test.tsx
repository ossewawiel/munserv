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

const mockHistory: StateHistoryEntry[] = [
  {
    state: 'reported',
    changedAt: '2024-01-12T10:00:00Z',
    changedBy: 'John Doe',
  },
  {
    state: 'confirmed',
    changedAt: '2024-01-14T14:00:00Z',
    changedBy: 'Admin User',
    note: 'Verified on site',
  },
  {
    state: 'in_progress',
    changedAt: '2024-01-18T09:00:00Z',
    changedBy: 'Maintenance Team',
  },
  {
    state: 'fixed',
    changedAt: '2024-01-20T16:00:00Z',
    changedBy: 'Maintenance Team',
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

  it('should display timeline entries horizontally', () => {
    const { container } = renderWithProviders(<HorizontalTimeline history={mockHistory} />);

    // Check for horizontal layout (flex with row direction or stepper)
    const timeline = container.querySelector('[role="list"]') ||
                     container.querySelector('.MuiStepper-root');
    expect(timeline).toBeInTheDocument();
  });

  it('should handle single entry', () => {
    const singleEntry: StateHistoryEntry[] = [{
      state: 'reported',
      changedAt: '2024-01-12T10:00:00Z',
      changedBy: 'John Doe',
    }];

    renderWithProviders(<HorizontalTimeline history={singleEntry} />);
    expect(screen.getByText('Reported')).toBeInTheDocument();
  });
});
