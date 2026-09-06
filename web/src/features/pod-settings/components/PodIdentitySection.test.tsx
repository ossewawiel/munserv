import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import type { ReactNode } from 'react';
import { server } from '@/test/mocks/server';
import { mockPodSettings } from '@/test/mocks/handlers';
import { PodIdentitySection } from './PodIdentitySection';

function renderWithProviders(ui: ReactNode) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>);
}

describe('PodIdentitySection', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  it('should prefill the form with the current pod name', async () => {
    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));
  });

  it('should reject a name shorter than two characters', async () => {
    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'W' } });

    expect(screen.getByText(/at least 2 characters/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /save changes/i })).toBeDisabled();
  });

  it('should send only the changed name when saved', async () => {
    let receivedBody: unknown;
    server.use(
      http.patch('*/pod/settings', async ({ request }) => {
        receivedBody = await request.json();
        return HttpResponse.json({
          name: 'Ward 42',
          displayName: 'Munserv Pod Ward 42',
          logoUrl: mockPodSettings.logoUrl,
        });
      })
    );

    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'Ward 42' } });
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    // logoUrl was not touched, so a name-only edit must not re-send it: doing
    // so would re-mark the pod_name setup step complete for no reason.
    await waitFor(() => expect(receivedBody).toEqual({ name: 'Ward 42' }));
    expect(await screen.findByText(/header now reads/i)).toBeInTheDocument();
  });

  it('should send only the changed logo URL when saved', async () => {
    let receivedBody: unknown;
    server.use(
      http.patch('*/pod/settings', async ({ request }) => {
        receivedBody = await request.json();
        return HttpResponse.json({
          name: mockPodSettings.name,
          displayName: mockPodSettings.displayName,
          logoUrl: 'https://cdn.ward42.org.za/branding/new-logo.png',
        });
      })
    );

    renderWithProviders(<PodIdentitySection />);

    const logoUrlField = await screen.findByLabelText(/logo url/i);
    await waitFor(() => expect(logoUrlField).toHaveValue(mockPodSettings.logoUrl));

    fireEvent.change(logoUrlField, {
      target: { value: 'https://cdn.ward42.org.za/branding/new-logo.png' },
    });
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    await waitFor(() =>
      expect(receivedBody).toEqual({ logoUrl: 'https://cdn.ward42.org.za/branding/new-logo.png' })
    );
  });

  it('should reject a logo URL longer than 500 characters', async () => {
    renderWithProviders(<PodIdentitySection />);

    const logoUrlField = await screen.findByLabelText(/logo url/i);
    await waitFor(() => expect(logoUrlField).toHaveValue(mockPodSettings.logoUrl));

    fireEvent.change(logoUrlField, { target: { value: `https://example.com/${'a'.repeat(500)}` } });

    expect(screen.getByText(/500 characters or fewer/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /save changes/i })).toBeDisabled();
  });

  it('should show the server validation message on 400', async () => {
    server.use(
      http.patch('*/pod/settings', () =>
        HttpResponse.json(
          { code: 'validation_error', message: 'Logo URL must be a valid http or https address.' },
          { status: 400 }
        )
      )
    );

    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    expect(
      await screen.findByText(/Logo URL must be a valid http or https address\./i)
    ).toBeInTheDocument();
  });
});
