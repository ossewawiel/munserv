import { defineConfig } from 'vitest/config';
import { loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { checkDemoAccountsInput } from './config/demoAccountsInput.ts';

const API_TARGET = 'http://localhost:8080';
// `vite preview` serves the showcase build; the console points it at the showcase backend.
const previewApiTarget = process.env.PREVIEW_API_TARGET ?? API_TARGET;

// https://vite.dev/config/
export default defineConfig(({ command, mode }) => {
  if (command === 'build') {
    // Vite stops a build only on a thrown error, so the check Result becomes an exception here.
    const check = checkDemoAccountsInput(loadEnv(mode, __dirname, 'VITE_').VITE_DEMO_ACCOUNTS);
    if (!check.ok) throw new Error(`VITE_DEMO_ACCOUNTS is set but invalid: ${check.reason}`);
  }
  return {
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: API_TARGET,
        changeOrigin: true,
      },
    },
  },
  preview: {
    proxy: {
      '/api': {
        target: previewApiTarget,
        changeOrigin: true,
      },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    exclude: ['node_modules', 'e2e/**/*'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/main.tsx',
      ],
    },
  },
};
});
