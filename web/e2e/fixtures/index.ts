/* eslint-disable react-hooks/rules-of-hooks */
import { test as base, type Page } from '@playwright/test';

/**
 * Page Object Model for Login Page
 */
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel(/email/i).fill(email);
    await this.page.getByLabel(/password/i).fill(password);
    await this.page.getByRole('button', { name: /sign in|login/i }).click();
  }

  async expectError(message: string | RegExp) {
    await this.page.getByText(message).waitFor({ state: 'visible' });
  }

  async clickRegisterLink() {
    await this.page.getByRole('link', { name: /register as a new member/i }).click();
  }
}

/**
 * Page Object Model for Register Page
 */
export class RegisterPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/register');
  }

  async expectLoaded() {
    await this.page.getByText(/register as a community member/i).waitFor({ state: 'visible' });
  }

  async fillPersonalInfo(firstName: string, surname: string) {
    await this.page.getByLabel(/first name/i).fill(firstName);
    await this.page.getByLabel(/surname/i).fill(surname);
  }

  async fillContactInfo(email: string, phone: string) {
    await this.page.getByLabel(/email/i).fill(email);
    await this.page.getByLabel(/phone number/i).fill(phone);
  }

  async fillAddress(address: string) {
    await this.page.getByLabel(/street address/i).fill(address);
  }

  async clickGetLocation() {
    await this.page.getByRole('button', { name: /get my location/i }).click();
  }

  async selectSector(sectorName: string) {
    await this.page.getByLabel(/community\/ward/i).click();
    await this.page.getByRole('option', { name: new RegExp(sectorName, 'i') }).click();
  }

  async submit() {
    await this.page.getByRole('button', { name: /submit registration/i }).click();
  }

  async expectSuccess() {
    await this.page.getByText(/registration submitted/i).waitFor({ state: 'visible' });
  }

  async expectError(message: string | RegExp) {
    await this.page.getByText(message).waitFor({ state: 'visible' });
  }

  async expectValidationError(_fieldLabel: string | RegExp) {
    await this.page.getByText(/this field is required/i).waitFor({ state: 'visible' });
  }

  async expectLocationCaptured() {
    await this.page.getByRole('button', { name: /location captured/i }).waitFor({ state: 'visible' });
  }

  async clickBackToLogin() {
    await this.page.getByRole('link', { name: /log in here|back to login/i }).click();
  }
}

/**
 * Page Object Model for Dashboard Page
 */
export class DashboardPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/dashboard');
  }

  async expectLoaded() {
    await this.page.getByRole('heading', { name: /dashboard/i }).waitFor({ state: 'visible' });
  }

  async getStatCard(label: string) {
    return this.page.getByTestId('stat-card').filter({ hasText: label });
  }
}

/**
 * Page Object Model for Issues Page
 */
export class IssuesPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/issues');
  }

  async expectLoaded() {
    await this.page.getByRole('heading', { name: /issues/i }).waitFor({ state: 'visible' });
  }

  async filterByState(state: string) {
    await this.page.getByLabel(/state/i).click();
    await this.page.getByRole('option', { name: new RegExp(state, 'i') }).click();
  }

  async filterByType(type: string) {
    await this.page.getByLabel(/type/i).click();
    await this.page.getByRole('option', { name: new RegExp(type, 'i') }).click();
  }

  async clickIssue(index = 0) {
    await this.page.getByRole('row').nth(index + 1).click(); // +1 for header row
  }
}

/**
 * Page Object Model for Issue Detail Page
 */
export class IssueDetailPage {
  constructor(private page: Page) {}

  async expectLoaded() {
    await this.page.getByTestId('issue-detail').waitFor({ state: 'visible' });
  }

  async changeState(newState: string) {
    await this.page.getByRole('button', { name: /change state/i }).click();
    await this.page.getByRole('option', { name: new RegExp(newState, 'i') }).click();
    await this.page.getByRole('button', { name: /confirm|save/i }).click();
  }
}

/**
 * Extended test fixtures with Page Objects
 */
export const test = base.extend<{
  loginPage: LoginPage;
  registerPage: RegisterPage;
  dashboardPage: DashboardPage;
  issuesPage: IssuesPage;
  issueDetailPage: IssueDetailPage;
}>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  registerPage: async ({ page }, use) => {
    await use(new RegisterPage(page));
  },
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },
  issuesPage: async ({ page }, use) => {
    await use(new IssuesPage(page));
  },
  issueDetailPage: async ({ page }, use) => {
    await use(new IssueDetailPage(page));
  },
});

export { expect } from '@playwright/test';
