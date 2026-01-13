import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { IssueDetailHeader } from './IssueDetailHeader';
import type { IssueType, IssueState } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          back: 'Back',
        },
        issues: {
          changeState: 'Change State',
          types: {
            pothole: 'Pothole',
            water_leak: 'Water Leak',
          },
          states: {
            reported: 'Reported',
            confirmed: 'Confirmed',
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

describe('IssueDetailHeader', () => {
  const defaultProps = {
    type: 'pothole' as IssueType,
    state: 'reported' as IssueState,
    heat: 65,
    onBack: vi.fn(),
    onChangeState: vi.fn(),
  };

  it('should render type badge', () => {
    renderWithProviders(<IssueDetailHeader {...defaultProps} />);
    expect(screen.getByText('Pothole')).toBeInTheDocument();
  });

  it('should render state badge', () => {
    renderWithProviders(<IssueDetailHeader {...defaultProps} />);
    expect(screen.getByText('Reported')).toBeInTheDocument();
  });

  it('should render heat indicator', () => {
    renderWithProviders(<IssueDetailHeader {...defaultProps} />);
    expect(screen.getByText('65')).toBeInTheDocument();
  });

  it('should render back button and call onBack when clicked', async () => {
    const onBack = vi.fn();
    renderWithProviders(<IssueDetailHeader {...defaultProps} onBack={onBack} />);

    const backButton = screen.getByRole('button', { name: /back/i });
    expect(backButton).toBeInTheDocument();

    await fireEvent.click(backButton);
    expect(onBack).toHaveBeenCalledTimes(1);
  });

  it('should render change state button and call onChangeState when clicked', async () => {
    const onChangeState = vi.fn();
    renderWithProviders(<IssueDetailHeader {...defaultProps} onChangeState={onChangeState} />);

    const changeStateButton = screen.getByRole('button', { name: /change state/i });
    expect(changeStateButton).toBeInTheDocument();

    await fireEvent.click(changeStateButton);
    expect(onChangeState).toHaveBeenCalledTimes(1);
  });

  it('should be wrapped in a card with proper styling', () => {
    const { container } = renderWithProviders(<IssueDetailHeader {...defaultProps} />);

    // Card should have MUI Paper/Card styling
    const card = container.firstChild;
    expect(card).toHaveClass('MuiPaper-root');
  });
});
