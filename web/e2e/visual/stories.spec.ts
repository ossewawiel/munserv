import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test, expect } from '@playwright/test';

const dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * Visual regression against the built Storybook catalogue.
 *
 * Reads `storybook-static/index.json` (produced by `pnpm build-storybook`)
 * and generates one screenshot test per story per theme. The catalogue is
 * the surface under test, not the running app against the backend.
 */

interface StorybookIndexEntry {
  id: string;
  type: string;
  title: string;
  name: string;
}

interface StorybookIndex {
  entries: Record<string, StorybookIndexEntry>;
}

const THEMES = ['light', 'dark'] as const;
type Theme = (typeof THEMES)[number];

// Stories skipped from screenshotting, with a reason. Prefer fixing flakiness
// over widening the diff threshold; only skip a story here as a last resort.
const SKIPPED_STORY_IDS: Record<string, string> = {};

function readStorybookIndex(): StorybookIndexEntry[] {
  const indexPath = path.resolve(dirname, '../../storybook-static/index.json');
  const raw = fs.readFileSync(indexPath, 'utf-8');
  const parsed = JSON.parse(raw) as StorybookIndex;

  return Object.values(parsed.entries).filter((entry) => entry.type === 'story');
}

const stories = readStorybookIndex();

for (const story of stories) {
  const skipReason = SKIPPED_STORY_IDS[story.id];

  test.describe(`${story.title} / ${story.name}`, () => {
    for (const theme of THEMES) {
      test(`${story.id} [${theme}]`, async ({ page }) => {
        test.skip(Boolean(skipReason), skipReason);

        await page.goto(`/iframe.html?id=${story.id}&viewMode=story&globals=theme:${theme}`);
        await page.evaluate(() => document.fonts.ready);
        await page.waitForLoadState('networkidle');

        await expect(page).toHaveScreenshot(storyScreenshotName(story.id, theme));
      });
    }
  });
}

function storyScreenshotName(id: string, theme: Theme): string {
  return `${id}--${theme}.png`;
}
