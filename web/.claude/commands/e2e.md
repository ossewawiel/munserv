# Playwright E2E Test Generator

name: "e2e"
description: "Generate Playwright E2E tests for user flows"
parameters:
  - name: "flow"
    description: "User flow description (e.g., 'login and view dashboard', 'create new issue')"
    required: true
  - name: "pages"
    description: "Comma-separated page names involved (e.g., login,dashboard,issues)"
    required: false

---

You are an expert QA engineer creating Playwright E2E tests for the MunServ web admin portal.

## Task

Generate E2E test for the user flow: "{{flow}}"

## Test File Location

`e2e/{{flow-name}}.spec.ts`

## Best Practices (ENFORCED)

### Use Page Object Model
```typescript
import { test, expect } from '../fixtures';  // Extended fixtures

test('user can complete flow', async ({ loginPage, dashboardPage }) => {
  // Use page objects instead of raw selectors
  await loginPage.goto();
  await loginPage.login('admin@ward42.example.com', 'admin123');
  await dashboardPage.expectLoaded();
});
```

### Prefer Locators over Selectors
```typescript
// GOOD - Role-based
page.getByRole('button', { name: /submit/i })
page.getByRole('heading', { level: 1 })
page.getByRole('textbox', { name: /email/i })

// GOOD - Label-based
page.getByLabel('Email')
page.getByPlaceholder('Enter email')

// GOOD - Text-based
page.getByText('Welcome')
page.getByText(/loading/i)

// AVOID - CSS selectors
page.locator('.submit-btn')  // Only when necessary
page.locator('[data-testid="submit"]')  // Last resort
```

### Network Interception
```typescript
// Wait for API response
await page.waitForResponse((res) =>
  res.url().includes('/api/v1/issues') && res.status() === 200
);

// Mock API response
await page.route('/api/v1/issues', async (route) => {
  await route.fulfill({
    status: 200,
    body: JSON.stringify({ items: [], total: 0 }),
  });
});
```

## E2E Test Template

```typescript
import { test, expect } from '../fixtures';

test.describe('{{FlowName}}', () => {
  test.beforeEach(async ({ page }) => {
    // Common setup
  });

  test('should complete the flow successfully', async ({
    page,
    loginPage,
    // other page objects
  }) => {
    // Step 1: Navigate
    await loginPage.goto();

    // Step 2: Authenticate
    await loginPage.login('admin@ward42.example.com', 'admin123');

    // Step 3: Wait for navigation
    await expect(page).toHaveURL('/dashboard');

    // Step 4: Verify content
    await expect(page.getByRole('heading', { name: /dashboard/i })).toBeVisible();

    // Step 5: Perform action
    await page.getByRole('link', { name: /issues/i }).click();

    // Step 6: Assert outcome
    await expect(page).toHaveURL('/issues');
    await expect(page.getByRole('table')).toBeVisible();
  });

  test('should handle error case', async ({ page, loginPage }) => {
    await loginPage.goto();
    await loginPage.login('wrong@example.com', 'wrongpass');

    await expect(page.getByText(/invalid credentials/i)).toBeVisible();
    await expect(page).toHaveURL('/login');
  });
});
```

## Common Flow Templates

### Authentication Flow
```typescript
test.describe('Authentication', () => {
  test('should login successfully', async ({ loginPage, dashboardPage }) => {
    await loginPage.goto();
    await loginPage.login('admin@ward42.example.com', 'admin123');
    await dashboardPage.expectLoaded();
  });

  test('should show error on invalid credentials', async ({ loginPage }) => {
    await loginPage.goto();
    await loginPage.login('wrong@example.com', 'wrongpass');
    await loginPage.expectError(/invalid/i);
  });

  test('should redirect to login when unauthorized', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL('/login');
  });
});
```

### CRUD Flow
```typescript
test.describe('Issue Management', () => {
  test.beforeEach(async ({ loginPage }) => {
    await loginPage.goto();
    await loginPage.login('admin@ward42.example.com', 'admin123');
  });

  test('should view issue list', async ({ issuesPage }) => {
    await issuesPage.goto();
    await issuesPage.expectLoaded();
  });

  test('should filter issues by state', async ({ issuesPage }) => {
    await issuesPage.goto();
    await issuesPage.filterByState('confirmed');

    // Verify filter applied (check URL or results)
  });

  test('should view issue detail', async ({ page, issuesPage, issueDetailPage }) => {
    await issuesPage.goto();
    await issuesPage.clickIssue(0);
    await issueDetailPage.expectLoaded();
  });

  test('should change issue state', async ({ page, issuesPage, issueDetailPage }) => {
    await issuesPage.goto();
    await issuesPage.clickIssue(0);
    await issueDetailPage.changeState('confirmed');

    await expect(page.getByText(/confirmed/i)).toBeVisible();
  });
});
```

### Form Submission Flow
```typescript
test.describe('Create Issue', () => {
  test('should create issue successfully', async ({ page }) => {
    // Navigate to form
    await page.goto('/issues/new');

    // Fill form
    await page.getByLabel('Type').click();
    await page.getByRole('option', { name: 'Pothole' }).click();
    await page.getByLabel('Description').fill('Large pothole on Main Street');

    // Submit
    await page.getByRole('button', { name: /create/i }).click();

    // Wait for API
    await page.waitForResponse((res) =>
      res.url().includes('/api/v1/issues') && res.status() === 201
    );

    // Verify redirect
    await expect(page).toHaveURL(/\/issues\/[\w-]+/);
  });

  test('should show validation errors', async ({ page }) => {
    await page.goto('/issues/new');

    // Submit without filling
    await page.getByRole('button', { name: /create/i }).click();

    // Verify errors
    await expect(page.getByText(/required/i)).toBeVisible();
  });
});
```

## Page Object Pattern

Create/update in `e2e/fixtures/index.ts`:

```typescript
export class {{PageName}}Page {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/{{path}}');
  }

  async expectLoaded() {
    await this.page.getByRole('heading', { name: /{{title}}/i }).waitFor({ state: 'visible' });
  }

  async {{action}}({{params}}) {
    // Implement action
  }
}
```

## Visual Regression (Optional)

```typescript
test('should match snapshot', async ({ page }) => {
  await page.goto('/dashboard');

  // Wait for content to load
  await page.waitForLoadState('networkidle');

  // Compare screenshot
  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixels: 100,
  });
});
```

## Output

1. Generate test file in `e2e/` directory
2. Use existing fixtures from `e2e/fixtures/index.ts`
3. Create new page objects if needed
4. Include happy path and error cases
5. Use proper Playwright locators (role > label > text)
6. Add network assertions where relevant
