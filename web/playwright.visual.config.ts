import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for visual regression against the Storybook catalogue.
 *
 * The catalogue is the surface under test, not the running app against the
 * backend: `pnpm build-storybook` produces `storybook-static/`, which this
 * config serves on port 6007 via `http-server`.
 *
 * @see https://playwright.dev/docs/test-snapshots
 */
export default defineConfig({
  testDir: './e2e/visual',
  // No {platform}/{projectName} segments: baselines are Linux + chromium only,
  // so the default template's platform suffix would duplicate that fact in the path.
  snapshotPathTemplate: '{testDir}/__screenshots__/{testFileBaseName}/{arg}{ext}',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never', outputFolder: 'playwright-report-visual' }],
    ['list'],
  ],
  use: {
    baseURL: 'http://localhost:6007',
    viewport: { width: 1280, height: 800 },
    deviceScaleFactor: 1,
    trace: 'off',
    screenshot: 'off',
  },
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.002,
      animations: 'disabled',
    },
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'pnpm exec http-server storybook-static -p 6007 -s',
    url: 'http://localhost:6007',
    reuseExistingServer: !process.env.CI,
    timeout: 60000,
  },
});
