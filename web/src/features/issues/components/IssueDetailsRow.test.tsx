import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { IssueDetailsRow } from './IssueDetailsRow';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        issues: {
          location: 'Location',
          reportCount: 'Report Count',
          createdAt: 'Created',
          updatedAt: 'Last Updated',
          description: 'Description',
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

describe('IssueDetailsRow', () => {
  const defaultProps = {
    address: '123 Main Street, Johannesburg',
    reportCount: 5,
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2024-01-18T14:30:00Z',
  };

  it('should render address', () => {
    renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    expect(screen.getByText('123 Main Street, Johannesburg')).toBeInTheDocument();
  });

  it('should render report count', () => {
    renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    expect(screen.getByText('5')).toBeInTheDocument();
  });

  it('should render created date formatted', () => {
    renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    // Date should be formatted
    expect(screen.getByText(/Jan.*15.*2024/i)).toBeInTheDocument();
  });

  it('should render updated date formatted', () => {
    renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    // Date should be formatted
    expect(screen.getByText(/Jan.*18.*2024/i)).toBeInTheDocument();
  });

  it('should render description when provided', () => {
    renderWithProviders(
      <IssueDetailsRow {...defaultProps} description="Large pothole causing damage to vehicles" />
    );
    expect(screen.getByText('Large pothole causing damage to vehicles')).toBeInTheDocument();
  });

  it('should not render description section when not provided', () => {
    renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    expect(screen.queryByText('Description')).not.toBeInTheDocument();
  });

  it('should be wrapped in a card', () => {
    const { container } = renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    const card = container.firstChild;
    expect(card).toHaveClass('MuiPaper-root');
  });

  it('should display labels for each field', () => {
    renderWithProviders(<IssueDetailsRow {...defaultProps} />);
    expect(screen.getByText('Location')).toBeInTheDocument();
    expect(screen.getByText('Report Count')).toBeInTheDocument();
    expect(screen.getByText('Created')).toBeInTheDocument();
    expect(screen.getByText('Last Updated')).toBeInTheDocument();
  });
});
