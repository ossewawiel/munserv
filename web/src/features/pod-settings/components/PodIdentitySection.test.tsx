import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import type { ReactNode } from 'react';
import { server } from '@/test/mocks/server';
import { mockPodSettings } from '@/test/mocks/handlers';
import { FeedbackProvider } from '@/shared/hooks/FeedbackProvider';
import { PodIdentitySection } from './PodIdentitySection';

function renderWithProviders(ui: ReactNode) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <FeedbackProvider>{ui}</FeedbackProvider>
    </QueryClientProvider>
  );
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

  it('should show the saved confirmation in a snackbar', async () => {
    server.use(
      http.patch('*/pod/settings', () =>
        HttpResponse.json({
          name: 'Ward 42',
          displayName: 'Munserv Pod Ward 42',
          logoUrl: mockPodSettings.logoUrl,
        })
      )
    );

    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'Ward 42' } });
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    const alert = await screen.findByRole('alert');
    expect(alert).toHaveTextContent(/header now reads/i);
  });

  it('should not render an inline success alert after a save', async () => {
    server.use(
      http.patch('*/pod/settings', () =>
        HttpResponse.json({
          name: 'Ward 42',
          displayName: 'Munserv Pod Ward 42',
          logoUrl: mockPodSettings.logoUrl,
        })
      )
    );

    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'Ward 42' } });
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    await screen.findByRole('alert');

    // Only the snackbar's Alert exists - the card itself carries none.
    expect(screen.getAllByRole('alert')).toHaveLength(1);
  });

  it('should keep the server error inline when the save is rejected', async () => {
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

    const alert = await screen.findByText(/Logo URL must be a valid http or https address\./i);
    expect(alert).toBeInTheDocument();

    // The error stays on screen; it does not vanish like a snackbar would.
    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(
      screen.getByText(/Logo URL must be a valid http or https address\./i)
    ).toBeInTheDocument();
  });

  it('should disable reset while the form is pristine', async () => {
    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    expect(screen.getByRole('button', { name: /reset/i })).toBeDisabled();
  });

  it('should restore the saved name when reset is pressed', async () => {
    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'Something else' } });
    expect(screen.getByRole('button', { name: /reset/i })).toBeEnabled();

    fireEvent.click(screen.getByRole('button', { name: /reset/i }));

    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));
    expect(screen.getByRole('button', { name: /reset/i })).toBeDisabled();
  });

  it('should restore the saved logo URL when reset is pressed', async () => {
    renderWithProviders(<PodIdentitySection />);

    const logoUrlField = await screen.findByLabelText(/logo url/i);
    await waitFor(() => expect(logoUrlField).toHaveValue(mockPodSettings.logoUrl));

    fireEvent.change(logoUrlField, {
      target: { value: 'https://cdn.ward42.org.za/branding/wrong-logo.png' },
    });
    expect(screen.getByRole('button', { name: /reset/i })).toBeEnabled();

    fireEvent.click(screen.getByRole('button', { name: /reset/i }));

    await waitFor(() => expect(logoUrlField).toHaveValue(mockPodSettings.logoUrl));
    expect(screen.getByRole('button', { name: /reset/i })).toBeDisabled();
  });

  it('should restore the saved values after a rejected save', async () => {
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

    fireEvent.change(nameField, { target: { value: 'Something else' } });
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    await screen.findByText(/Logo URL must be a valid http or https address\./i);

    fireEvent.click(screen.getByRole('button', { name: /reset/i }));

    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));
    expect(screen.getByRole('button', { name: /reset/i })).toBeDisabled();
  });

  it('should disable both buttons while saving', async () => {
    server.use(http.patch('*/pod/settings', async () => new Promise(() => {})));

    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'Ward 42' } });
    fireEvent.click(screen.getByRole('button', { name: /save changes/i }));

    await waitFor(() => expect(screen.getByRole('button', { name: /save changes/i })).toBeDisabled());
    expect(screen.getByRole('button', { name: /reset/i })).toBeDisabled();
  });

  it('should not call the mutation when reset is pressed', async () => {
    let requestCount = 0;
    server.use(
      http.patch('*/pod/settings', () => {
        requestCount += 1;
        return HttpResponse.json(mockPodSettings);
      })
    );

    renderWithProviders(<PodIdentitySection />);

    const nameField = await screen.findByLabelText(/pod name/i);
    await waitFor(() => expect(nameField).toHaveValue(mockPodSettings.name));

    fireEvent.change(nameField, { target: { value: 'Something else' } });
    fireEvent.click(screen.getByRole('button', { name: /reset/i }));

    expect(requestCount).toBe(0);
  });
});
