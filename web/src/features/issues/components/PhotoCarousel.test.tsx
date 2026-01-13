import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { PhotoCarousel } from './PhotoCarousel';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          noResults: 'No results',
          close: 'Close',
          previous: 'Previous',
          next: 'Next',
        },
        issues: {
          photos: 'Photos',
          photoOf: '{{current}} of {{total}}',
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

const mockPhotos = [
  'https://example.com/photo1.jpg',
  'https://example.com/photo2.jpg',
  'https://example.com/photo3.jpg',
];

describe('PhotoCarousel', () => {
  it('should render all photos horizontally', () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // All photos should be visible (square thumbnails side by side)
    const images = screen.getAllByRole('img');
    expect(images).toHaveLength(3);
    expect(images[0]).toHaveAttribute('src', mockPhotos[0]);
    expect(images[1]).toHaveAttribute('src', mockPhotos[1]);
    expect(images[2]).toHaveAttribute('src', mockPhotos[2]);
  });

  it('should show empty state when no photos', () => {
    renderWithProviders(<PhotoCarousel photos={[]} />);
    expect(screen.getByText('No results')).toBeInTheDocument();
  });

  it('should render clickable buttons for each photo', () => {
    const { container } = renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Each photo should be wrapped in a clickable button with role="tab"
    const tabs = container.querySelectorAll('[role="tab"]');
    expect(tabs).toHaveLength(3);
  });

  it('should always show navigation arrows', () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Both arrows should always be visible
    expect(screen.getByRole('button', { name: /previous/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /next/i })).toBeInTheDocument();
  });

  it('should show disabled navigation arrows for single photo', () => {
    renderWithProviders(<PhotoCarousel photos={[mockPhotos[0]]} />);

    // Arrows visible but disabled for single photo
    const prevButton = screen.getByRole('button', { name: /previous/i });
    const nextButton = screen.getByRole('button', { name: /next/i });
    expect(prevButton).toBeInTheDocument();
    expect(nextButton).toBeInTheDocument();
    expect(prevButton).toBeDisabled();
    expect(nextButton).toBeDisabled();
  });

  it('should render single photo centered', () => {
    renderWithProviders(<PhotoCarousel photos={[mockPhotos[0]]} />);

    const images = screen.getAllByRole('img');
    expect(images).toHaveLength(1);
    expect(images[0]).toHaveAttribute('src', mockPhotos[0]);
  });

  it('should open lightbox dialog when clicking on photo', async () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Click on the first photo
    const images = screen.getAllByRole('img');
    await fireEvent.click(images[0]);

    // Dialog should open with larger image
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('should close lightbox dialog when clicking close button', async () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Open dialog by clicking photo
    const images = screen.getAllByRole('img');
    await fireEvent.click(images[0]);

    // Wait for dialog to open
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    // Close dialog
    const closeButton = screen.getByRole('button', { name: /close/i });
    await fireEvent.click(closeButton);

    // Wait for dialog to close (MUI uses animation)
    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    }, { timeout: 1000 });
  });

  it('should navigate photos in lightbox dialog', async () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Open dialog by clicking first photo
    const images = screen.getAllByRole('img');
    await fireEvent.click(images[0]);

    // Wait for dialog to open
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    // Navigate to next in dialog
    const nextButton = screen.getByRole('button', { name: /next/i });
    await fireEvent.click(nextButton);

    // Should show counter showing photo 2 of 3
    expect(screen.getByText(/2 of 3/i)).toBeInTheDocument();
  });

  it('should open lightbox at correct index when clicking different photos', async () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Click on the third photo
    const images = screen.getAllByRole('img');
    await fireEvent.click(images[2]);

    // Wait for dialog to open
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    // Should show counter showing photo 3 of 3
    expect(screen.getByText(/3 of 3/i)).toBeInTheDocument();
  });

  it('should wrap around when navigating past last photo in lightbox', async () => {
    renderWithProviders(<PhotoCarousel photos={mockPhotos} />);

    // Open dialog at last photo
    const images = screen.getAllByRole('img');
    await fireEvent.click(images[2]);

    // Wait for dialog to open
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    // Navigate to next (should wrap to first)
    const nextButton = screen.getByRole('button', { name: /next/i });
    await fireEvent.click(nextButton);

    // Should show counter showing photo 1 of 3
    expect(screen.getByText(/1 of 3/i)).toBeInTheDocument();
  });
});
