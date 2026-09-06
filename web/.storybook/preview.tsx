import type { Decorator, Preview } from '@storybook/react-vite';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';

import i18n from '@/lib/i18n';
import { ThemeProvider } from '@/theme';
import { worker } from '@/test/mocks/browser';

const COLOR_MODE_STORAGE_KEY = 'munserv-color-mode';

// The catalogue always renders in English regardless of the reader's browser locale.
void i18n.changeLanguage('en');

// Stories that trigger a real mutation (e.g. pod settings save) need a backend
// to answer; the catalogue has none, so MSW intercepts fetches in the browser
// with the same handlers Vitest uses. Unhandled requests pass through so
// static assets keep loading. start() is async (service-worker registration
// and activation), so it is awaited through a loader below: without that, the
// first story to render can fire a request before the worker is active and
// it escapes to the real network.
const mswReady = worker.start({ onUnhandledRequest: 'bypass' });

const withProviders: Decorator = (Story, context) => {
  const mode = context.globals.theme as 'light' | 'dark' | 'system';
  localStorage.setItem(COLOR_MODE_STORAGE_KEY, mode);

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return (
    <MemoryRouter>
      <QueryClientProvider client={queryClient}>
        <I18nextProvider i18n={i18n}>
          {/* key forces the theme provider to re-read the persisted color mode on toolbar change */}
          <ThemeProvider key={mode}>
            <Story />
          </ThemeProvider>
        </I18nextProvider>
      </QueryClientProvider>
    </MemoryRouter>
  );
};

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
  globalTypes: {
    theme: {
      description: 'Colour mode',
      defaultValue: 'light',
      toolbar: {
        title: 'Theme',
        icon: 'mirror',
        items: [
          { value: 'light', title: 'Light' },
          { value: 'dark', title: 'Dark' },
          { value: 'system', title: 'System' },
        ],
        dynamicTitle: true,
      },
    },
  },
  decorators: [withProviders],
  loaders: [
    async () => {
      await mswReady;
      return {};
    },
  ],
  // Runtime handler overrides (worker.use in a story's beforeEach) must never
  // leak into the next story, or an unrelated story could inherit them.
  beforeEach: () => {
    worker.resetHandlers();
  },
};

export default preview;
