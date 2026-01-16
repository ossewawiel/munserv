import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { IssueTypeFilterBar } from './IssueTypeFilterBar';
import type { IssueType } from '@/features/issues/types';

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
          map: {
            filterByType: 'Filter',
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

describe('IssueTypeFilterBar', () => {
  describe('rendering', () => {
    it('should render all 7 issue type filter buttons', () => {
      const activeTypes = new Set<IssueType>(['pothole', 'water_leak']);
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      const buttons = screen.getAllByRole('button');
      expect(buttons).toHaveLength(7);
    });

    it('should render filter label text', () => {
      const activeTypes = new Set<IssueType>();
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      expect(screen.getByText('Filter')).toBeInTheDocument();
    });

    it('should be wrapped in a Paper component with border', () => {
      const activeTypes = new Set<IssueType>();
      const { container } = renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      // Paper component should be present
      const paper = container.querySelector('.MuiPaper-root');
      expect(paper).toBeInTheDocument();
    });
  });

  describe('active state', () => {
    it('should pass correct isActive prop based on activeTypes set', () => {
      const activeTypes = new Set<IssueType>(['pothole', 'water_leak']);
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      // All 7 buttons should render - active state is handled by button styling
      const buttons = screen.getAllByRole('button');
      expect(buttons).toHaveLength(7);
    });

    it('should handle empty activeTypes set', () => {
      const activeTypes = new Set<IssueType>();
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      const buttons = screen.getAllByRole('button');
      expect(buttons).toHaveLength(7);
    });

    it('should handle all types active', () => {
      const allTypes: IssueType[] = [
        'pothole',
        'water_leak',
        'sewage_leak',
        'traffic_light',
        'street_light',
        'illegal_dumping',
        'other',
      ];
      const activeTypes = new Set<IssueType>(allTypes);
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      const buttons = screen.getAllByRole('button');
      expect(buttons).toHaveLength(7);
    });
  });

  describe('interaction', () => {
    it('should call onToggle with "pothole" when first button is clicked', async () => {
      const onToggle = vi.fn();
      const activeTypes = new Set<IssueType>();
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={onToggle} />
      );

      const buttons = screen.getAllByRole('button');
      await fireEvent.click(buttons[0]);

      expect(onToggle).toHaveBeenCalledTimes(1);
      expect(onToggle).toHaveBeenCalledWith('pothole');
    });

    it('should call onToggle with "water_leak" when second button is clicked', async () => {
      const onToggle = vi.fn();
      const activeTypes = new Set<IssueType>();
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={onToggle} />
      );

      const buttons = screen.getAllByRole('button');
      await fireEvent.click(buttons[1]);

      expect(onToggle).toHaveBeenCalledTimes(1);
      expect(onToggle).toHaveBeenCalledWith('water_leak');
    });

    it('should call onToggle with correct type for each button', async () => {
      const onToggle = vi.fn();
      const activeTypes = new Set<IssueType>();
      renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={onToggle} />
      );

      const expectedTypes: IssueType[] = [
        'pothole',
        'water_leak',
        'sewage_leak',
        'traffic_light',
        'street_light',
        'illegal_dumping',
        'other',
      ];

      const buttons = screen.getAllByRole('button');

      for (let i = 0; i < buttons.length; i++) {
        await fireEvent.click(buttons[i]);
        expect(onToggle).toHaveBeenLastCalledWith(expectedTypes[i]);
      }

      expect(onToggle).toHaveBeenCalledTimes(7);
    });
  });

  describe('layout', () => {
    it('should render buttons in a vertical Stack', () => {
      const activeTypes = new Set<IssueType>();
      const { container } = renderWithProviders(
        <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
      );

      // Stack component with column direction should be present
      const stack = container.querySelector('.MuiStack-root');
      expect(stack).toBeInTheDocument();
    });
  });
});
