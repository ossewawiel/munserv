import type { ReactElement } from 'react';
import type { Decorator, Meta, StoryObj } from '@storybook/react-vite';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { expect, userEvent, waitFor, within } from 'storybook/test';

import { worker } from '@/test/mocks/browser';
import { FeedbackProvider } from '@/shared/hooks/FeedbackProvider';
import { PodIdentitySection } from './PodIdentitySection';
import { podSettingsKeys } from '../hooks';
import type { PodSettings } from '../types';

// A local asset, not a remote URL: nothing outside the harness can fetch a
// real pod-logo URL, so every "with logo" baseline showed a broken-image
// glyph. This one always resolves, in Storybook and in the screenshot gate.
const podWithLogo: PodSettings = {
  name: 'Ward42',
  displayName: 'Munserv Pod Ward42',
  logoUrl: '/assets/app-mark.png',
};

const podWithoutLogo: PodSettings = {
  name: 'Ward42',
  displayName: 'Munserv Pod Ward42',
  logoUrl: null,
};

function withQueryData(settings: PodSettings): Decorator {
  return (Story): ReactElement => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          staleTime: Infinity,
          refetchOnMount: false,
          refetchOnWindowFocus: false,
        },
        mutations: { retry: false },
      },
    });
    queryClient.setQueryData(podSettingsKeys.all, settings);

    return (
      <QueryClientProvider client={queryClient}>
        <FeedbackProvider>
          <Story />
        </FeedbackProvider>
      </QueryClientProvider>
    );
  };
}

const meta = {
  title: 'Features/PodSettings/PodIdentitySection',
  component: PodIdentitySection,
} satisfies Meta<typeof PodIdentitySection>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Main: Story = {
  decorators: [withQueryData(podWithLogo)],
};

export const IdentityNoLogo: Story = {
  decorators: [withQueryData(podWithoutLogo)],
};

export const IdentityDirty: Story = {
  decorators: [withQueryData(podWithLogo)],
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const nameField = await canvas.findByLabelText(/pod name/i);

    await waitFor(() => expect(nameField).toHaveValue(podWithLogo.name));

    await userEvent.clear(nameField);
    await userEvent.type(nameField, 'Ward 42');

    await expect(canvas.getByRole('button', { name: /reset/i })).toBeEnabled();
    await expect(canvas.getByRole('button', { name: /save changes/i })).toBeEnabled();
  },
};

export const IdentityInvalidName: Story = {
  decorators: [withQueryData(podWithLogo)],
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const nameField = await canvas.findByLabelText(/pod name/i);

    // The ref-guarded prefill effect races userEvent.clear: without waiting
    // for it first, the effect can rewrite the field after the clear and
    // the typed value gets appended to the original name instead of
    // replacing it.
    await waitFor(() => expect(nameField).toHaveValue(podWithLogo.name));

    await userEvent.clear(nameField);
    await userEvent.type(nameField, 'W');

    await expect(canvas.getByText(/at least 2 characters/i)).toBeInTheDocument();
    await expect(canvas.getByRole('button', { name: /save changes/i })).toBeDisabled();
  },
};

export const IdentitySaving: Story = {
  decorators: [withQueryData(podWithLogo)],
  beforeEach: () => {
    worker.use(http.patch('*/pod/settings', () => new Promise(() => {})));
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const nameField = await canvas.findByLabelText(/pod name/i);

    await waitFor(() => expect(nameField).toHaveValue(podWithLogo.name));

    await userEvent.clear(nameField);
    await userEvent.type(nameField, 'Ward 42');
    await userEvent.click(canvas.getByRole('button', { name: /save changes/i }));

    await waitFor(() => expect(canvas.getByRole('button', { name: /save changes/i })).toBeDisabled());
  },
};

export const IdentityServerError: Story = {
  decorators: [withQueryData(podWithLogo)],
  beforeEach: () => {
    worker.use(
      http.patch('*/pod/settings', () =>
        HttpResponse.json(
          { code: 'validation_error', message: 'Logo URL must be a valid http or https address.' },
          { status: 400 }
        )
      )
    );
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const logoUrlField = await canvas.findByLabelText(/logo url/i);

    await waitFor(() => expect(logoUrlField).toHaveValue(podWithLogo.logoUrl));

    await userEvent.clear(logoUrlField);
    await userEvent.type(logoUrlField, 'cdn.ward42.org.za/branding/pod-logo.png');
    await userEvent.click(canvas.getByRole('button', { name: /save changes/i }));

    await waitFor(() =>
      expect(canvas.getByText(/must be a valid http or https address/i)).toBeInTheDocument()
    );
  },
};

export const IdentitySaved: Story = {
  decorators: [withQueryData(podWithLogo)],
  beforeEach: () => {
    worker.use(
      http.patch('*/pod/settings', () =>
        HttpResponse.json({
          name: 'Ward 42',
          displayName: 'Munserv Pod Ward 42',
          logoUrl: podWithLogo.logoUrl,
        })
      )
    );
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    const nameField = await canvas.findByLabelText(/pod name/i);

    await waitFor(() => expect(nameField).toHaveValue(podWithLogo.name));

    await userEvent.clear(nameField);
    await userEvent.type(nameField, 'Ward 42');
    await userEvent.click(canvas.getByRole('button', { name: /save changes/i }));

    await waitFor(() => expect(canvas.getByText(/header now reads/i)).toBeInTheDocument());
  },
};
