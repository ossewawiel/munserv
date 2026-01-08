import { describe, it, expect, vi } from 'vitest';
import { render } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { IssuesTable } from './IssuesTable';
import type { IssueSummary } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        issues: {
          type: 'Type',
          state: 'State',
          heat: 'Heat',
          createdAt: 'Created',
          types: {
            pothole: 'Pothole',
          },
        },
        common: {
          noResults: 'No results',
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

const mockIssues: IssueSummary[] = [
  {
    id: 'issue-1',
    type: 'pothole',
    state: 'reported',
    location: { latitude: -26.2041, longitude: 28.0473 },
    heat: 45,
    thumbnailUrl: 'https://example.com/thumb1.jpg',
    createdAt: '2024-01-15T10:00:00Z',
  },
  {
    id: 'issue-2',
    type: 'water_leak',
    state: 'confirmed',
    location: { latitude: -26.2042, longitude: 28.0474 },
    heat: 72,
    thumbnailUrl: 'https://example.com/thumb2.jpg',
    createdAt: '2024-01-16T11:00:00Z',
  },
];

describe('IssuesTable', () => {
  describe('thumbnail rendering', () => {
    it('should render thumbnail images without Tailwind class-based styling', () => {
      const onRowClick = vi.fn();
      const { container } = renderWithProviders(
        <IssuesTable issues={mockIssues} onRowClick={onRowClick} />
      );

      // Find all img elements in the table
      const thumbnails = container.querySelectorAll('img');
      expect(thumbnails).toHaveLength(2);

      thumbnails.forEach((thumbnail) => {
        // Images should NOT have Tailwind/CSS class-based styling
        // The className attribute should NOT contain Tailwind utility classes
        const className = thumbnail.getAttribute('class') || '';
        expect(className).not.toContain('h-10');
        expect(className).not.toContain('w-10');
        expect(className).not.toContain('rounded');
        expect(className).not.toContain('object-cover');
      });
    });

    it('should render thumbnail images with accessible alt text', () => {
      const onRowClick = vi.fn();
      const { container } = renderWithProviders(
        <IssuesTable issues={mockIssues} onRowClick={onRowClick} />
      );

      const thumbnails = container.querySelectorAll('img');
      thumbnails.forEach((thumbnail) => {
        // Alt text should not be empty for accessibility
        const altText = thumbnail.getAttribute('alt');
        expect(altText).toBeTruthy();
        expect(altText).not.toBe('');
      });
    });

    it('should render thumbnails with MUI styling (no raw img className)', () => {
      const onRowClick = vi.fn();
      const { container } = renderWithProviders(
        <IssuesTable issues={mockIssues} onRowClick={onRowClick} />
      );

      const thumbnails = container.querySelectorAll('img');
      expect(thumbnails).toHaveLength(2);

      thumbnails.forEach((thumbnail) => {
        // MUI Box component with sx prop applies styles via CSS-in-JS
        // The element should have a MUI-generated class (e.g., css-xxx or MuiBox-root)
        const className = thumbnail.getAttribute('class') || '';
        // MUI generates classes that start with 'css-' or contain 'Mui'
        const hasMuiStyling = className.includes('css-') || className.includes('Mui');
        expect(hasMuiStyling).toBe(true);
      });
    });
  });
});
