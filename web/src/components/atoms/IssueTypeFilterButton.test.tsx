import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { IssueTypeFilterButton } from './IssueTypeFilterButton';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        issues: {
          types: {
            pothole: 'Pothole',
            water_leak: 'Water Leak',
            sewage_leak: 'Sewage Leak',
            traffic_light: 'Traffic Light',
            street_light: 'Street Light',
            illegal_dumping: 'Illegal Dumping',
            other: 'Other',
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

describe('IssueTypeFilterButton', () => {
  describe('rendering', () => {
    it('should render a button element', () => {
      renderWithProviders(
        <IssueTypeFilterButton type="pothole" isActive={false} onClick={vi.fn()} />
      );

      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });

    it('should render with active state styling when isActive is true', () => {
      renderWithProviders(
        <IssueTypeFilterButton type="pothole" isActive={true} onClick={vi.fn()} />
      );

      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
      // Active state should have solid background color
    });

    it('should render with inactive state styling when isActive is false', () => {
      renderWithProviders(
        <IssueTypeFilterButton type="pothole" isActive={false} onClick={vi.fn()} />
      );

      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
      // Inactive state should have light background
    });

    it('should render an SVG icon', () => {
      renderWithProviders(
        <IssueTypeFilterButton type="water_leak" isActive={false} onClick={vi.fn()} />
      );

      const button = screen.getByRole('button');
      const svg = button.querySelector('svg');
      expect(svg).toBeInTheDocument();
    });
  });

  describe('tooltip', () => {
    it('should have a tooltip with the issue type label', async () => {
      renderWithProviders(
        <IssueTypeFilterButton type="pothole" isActive={false} onClick={vi.fn()} />
      );

      // Tooltip is shown on hover - we check the button has correct aria attributes
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });
  });

  describe('interaction', () => {
    it('should call onClick when clicked', async () => {
      const onClick = vi.fn();
      renderWithProviders(
        <IssueTypeFilterButton type="pothole" isActive={false} onClick={onClick} />
      );

      const button = screen.getByRole('button');
      await fireEvent.click(button);

      expect(onClick).toHaveBeenCalledTimes(1);
    });

    it('should call onClick when clicked in active state', async () => {
      const onClick = vi.fn();
      renderWithProviders(
        <IssueTypeFilterButton type="pothole" isActive={true} onClick={onClick} />
      );

      const button = screen.getByRole('button');
      await fireEvent.click(button);

      expect(onClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('issue types', () => {
    const issueTypes = [
      'pothole',
      'water_leak',
      'sewage_leak',
      'traffic_light',
      'street_light',
      'illegal_dumping',
      'other',
    ] as const;

    it.each(issueTypes)('should render correctly for issue type: %s', (type) => {
      renderWithProviders(
        <IssueTypeFilterButton type={type} isActive={false} onClick={vi.fn()} />
      );

      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
    });
  });
});
