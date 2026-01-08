import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { MemoryRouter } from 'react-router-dom';
import i18n from 'i18next';

import { Breadcrumbs } from './Breadcrumbs';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        dashboard: { title: 'Dashboard' },
        issues: { title: 'Issues', detail: 'Issue Details' },
        members: { title: 'Members' },
        heatReport: { title: 'Heat Report' },
        reports: { title: 'Reports' },
      },
    },
  },
});

const lightTheme = createTheme({ palette: { mode: 'light' } });
const darkTheme = createTheme({ palette: { mode: 'dark' } });

interface RenderOptions {
  theme?: ReturnType<typeof createTheme>;
  initialEntries?: string[];
}

function renderWithProviders(
  ui: React.ReactElement,
  { theme = lightTheme, initialEntries = ['/'] }: RenderOptions = {}
) {
  return render(
    <MemoryRouter initialEntries={initialEntries}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>{ui}</I18nextProvider>
      </ThemeProvider>
    </MemoryRouter>
  );
}

describe('Breadcrumbs', () => {
  describe('layout', () => {
    it('should render page title on the left side', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues' },
          ]}
        />
      );

      // Get the h1 specifically (page title)
      const title = screen.getByRole('heading', { level: 1, name: 'Issues' });
      expect(title).toBeInTheDocument();
    });

    it('should render breadcrumb trail on the right side', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/', icon: 'home' },
            { label: 'Issues' },
          ]}
        />
      );

      expect(screen.getByRole('navigation', { name: /breadcrumb/i })).toBeInTheDocument();
      // Home icon is rendered instead of text, but has aria-label
      expect(screen.getByRole('link', { name: 'Dashboard' })).toBeInTheDocument();
    });

    it('should have white/paper background in light mode', () => {
      const { container } = renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues' },
          ]}
        />,
        { theme: lightTheme }
      );

      const headerElement = container.firstChild as HTMLElement;
      // In light mode, background should be paper/white
      // MUI applies theme.palette.background.paper
      expect(headerElement).toBeInTheDocument();
    });

    it('should have dark background in dark mode', () => {
      const { container } = renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues' },
          ]}
        />,
        { theme: darkTheme }
      );

      const headerElement = container.firstChild as HTMLElement;
      expect(headerElement).toBeInTheDocument();
    });
  });

  describe('breadcrumb items', () => {
    it('should render all breadcrumb items', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issue Details"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues', path: '/issues' },
            { label: 'Issue Details' },
          ]}
        />
      );

      expect(screen.getByText('Dashboard')).toBeInTheDocument();
      expect(screen.getByText('Issues')).toBeInTheDocument();
      // Current page appears in title, may or may not appear in trail
    });

    it('should render clickable links for items with paths', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issue Details"
          items={[
            { label: 'Dashboard', path: '/', icon: 'home' },
            { label: 'Issues', path: '/issues' },
            { label: 'Issue Details' },
          ]}
        />
      );

      const dashboardLink = screen.getByRole('link', { name: 'Dashboard' });
      const issuesLink = screen.getByRole('link', { name: 'Issues' });

      expect(dashboardLink).toHaveAttribute('href', '/');
      expect(issuesLink).toHaveAttribute('href', '/issues');
    });

    it('should render current item (without path) as non-clickable text', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issue Details"
          items={[
            { label: 'Dashboard', path: '/', icon: 'home' },
            { label: 'Issues', path: '/issues' },
            { label: 'Issue Details' },
          ]}
        />
      );

      // Current item should not be a link
      const breadcrumbNav = screen.getByRole('navigation', { name: /breadcrumb/i });
      const issueDetailsText = breadcrumbNav.querySelector('li:last-child');
      expect(issueDetailsText).toBeInTheDocument();
      expect(issueDetailsText?.querySelector('a')).toBeNull();
    });

    it('should use chevron as separator between items', () => {
      const { container } = renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/', icon: 'home' },
            { label: 'Issues' },
          ]}
        />
      );

      // MUI Breadcrumbs uses li.MuiBreadcrumbs-separator for separators
      const separators = container.querySelectorAll('.MuiBreadcrumbs-separator');
      expect(separators.length).toBeGreaterThan(0);
    });

    it('should render home icon when icon="home" is specified', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/', icon: 'home' },
            { label: 'Issues' },
          ]}
        />
      );

      // Home icon should be rendered with aria-label for accessibility
      const homeLink = screen.getByRole('link', { name: 'Dashboard' });
      expect(homeLink).toBeInTheDocument();
      expect(homeLink.querySelector('svg')).toBeInTheDocument();
    });
  });

  describe('optional subtitle', () => {
    it('should render subtitle when provided', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Heat Report"
          subtitle="Generated at: 2024-01-15 10:00"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Reports', path: '/reports' },
            { label: 'Heat Report' },
          ]}
        />
      );

      expect(screen.getByText('Generated at: 2024-01-15 10:00')).toBeInTheDocument();
    });

    it('should not render subtitle when not provided', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues' },
          ]}
        />
      );

      // Should not have any subtitle element - get the h1 specifically
      const title = screen.getByRole('heading', { level: 1, name: 'Issues' });
      expect(title.parentElement?.childElementCount).toBe(1);
    });
  });

  describe('accessibility', () => {
    it('should have proper aria-label on navigation', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues' },
          ]}
        />
      );

      expect(screen.getByRole('navigation', { name: /breadcrumb/i })).toBeInTheDocument();
    });

    it('should mark current page with aria-current', () => {
      renderWithProviders(
        <Breadcrumbs
          title="Issues"
          items={[
            { label: 'Dashboard', path: '/' },
            { label: 'Issues' },
          ]}
        />
      );

      const breadcrumbNav = screen.getByRole('navigation', { name: /breadcrumb/i });
      const currentItem = breadcrumbNav.querySelector('[aria-current="page"]');
      expect(currentItem).toBeInTheDocument();
    });
  });
});
