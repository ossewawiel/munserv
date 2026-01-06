import { StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import CircularProgress from '@mui/material/CircularProgress';
import Box from '@mui/material/Box';

import { queryClient } from '@/lib/query-client';
import { ThemeProvider } from '@/theme';
import '@/lib/i18n'; // Initialize i18n
import App from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <InitColorSchemeScript attribute="data-color-scheme" />
    <Suspense
      fallback={
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '100vh',
          }}
        >
          <CircularProgress />
        </Box>
      }
    >
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <ThemeProvider>
            <App />
          </ThemeProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </Suspense>
  </StrictMode>
);
