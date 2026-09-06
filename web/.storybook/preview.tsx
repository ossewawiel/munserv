import type { Decorator, Preview } from '@storybook/react-vite';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';

import i18n from '@/lib/i18n';
import { ThemeProvider } from '@/theme';

const COLOR_MODE_STORAGE_KEY = 'munserv-color-mode';

// The catalogue always renders in English regardless of the reader's browser locale.
void i18n.changeLanguage('en');

const withProviders: Decorator = (Story, context) => {
  const mode = context.globals.theme as 'light' | 'dark' | 'system';
  localStorage.setItem(COLOR_MODE_STORAGE_KEY, mode);

  // Stories that read useParams/useSearchParams set `parameters.router.initialEntries`
  // to control the single MemoryRouter's history; only one Router may exist per story.
  const initialEntries =
    (context.parameters.router as { initialEntries?: readonly string[] } | undefined)
      ?.initialEntries ?? ['/'];

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return (
    <MemoryRouter initialEntries={initialEntries}>
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
};

export default preview;
