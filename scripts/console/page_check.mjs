// Opens one page as a logged-in account, asserts text on it and saves a screenshot.
// Run by autocheck.py: `node page_check.mjs <web dir holding node_modules/playwright>`.
// stdin: {url, expect_text: [..], screenshot, session: {access, refresh, admin, support_grant, is_super_user} | null}
// stdout: {ok, problems: [..], title}
import { createRequire } from 'node:module';
import { join } from 'node:path';

const NAVIGATION_TIMEOUT_MS = 30000;
const TEXT_TIMEOUT_MS = 10000;
const VIEWPORT = { width: 1280, height: 720 };

const chunks = [];
for await (const chunk of process.stdin) chunks.push(chunk);
const job = JSON.parse(Buffer.concat(chunks).toString('utf8'));

const { chromium } = createRequire(join(process.argv[2], 'package.json'))('playwright');
const browser = await chromium.launch();
const problems = [];
let title = null;
try {
  const context = await browser.newContext({ viewport: VIEWPORT });
  const { session } = job;
  if (session) {
    // The web client reads these keys from localStorage (web/src/features/auth/hooks.ts).
    const entries = {
      accessToken: session.access,
      refreshToken: session.refresh,
      admin: session.admin ? JSON.stringify(session.admin) : null,
      supportGrant: session.support_grant ? JSON.stringify(session.support_grant) : null,
      isSuperUser: session.is_super_user ? 'true' : null,
    };
    await context.addInitScript((values) => {
      for (const [key, value] of Object.entries(values)) {
        if (value !== null) window.localStorage.setItem(key, value);
      }
    }, entries);
  }
  const page = await context.newPage();
  // `load`, not `networkidle`: on any host but localhost the app asks for the pod theme, the 401 answer
  // never counts as finished, and networkidle times out. The text waits below prove the page rendered.
  await page.goto(job.url, { waitUntil: 'load', timeout: NAVIGATION_TIMEOUT_MS });
  for (const text of job.expect_text) {
    try {
      await page.getByText(text).first().waitFor({ state: 'visible', timeout: TEXT_TIMEOUT_MS });
    } catch {
      problems.push(`text not visible: ${text}`);
    }
  }
  title = await page.title();
  await page.screenshot({ path: job.screenshot, fullPage: true });
} catch (error) {
  problems.push(String(error.message).split('\n')[0]);
} finally {
  await browser.close();
}
process.stdout.write(JSON.stringify({ ok: problems.length === 0, problems, title }));
