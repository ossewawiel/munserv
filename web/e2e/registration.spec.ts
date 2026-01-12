import { test, expect } from './fixtures';

/**
 * E2E tests for member registration flow
 *
 * These tests cover the complete registration journey:
 * 1. Navigation from login to register
 * 2. Form validation
 * 3. Successful registration with geolocation
 * 4. Success message display
 */

test.describe('Member Registration Flow', () => {
  test.describe('navigation', () => {
    test('should navigate from login page to register page', async ({ loginPage, page }) => {
      await loginPage.goto();
      await loginPage.clickRegisterLink();

      await expect(page).toHaveURL('/register');
      await expect(page.getByText(/register as a community member/i)).toBeVisible();
    });

    test('should navigate back to login from register page', async ({ registerPage, page }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Find and click the "Log in here" or similar link
      await page.getByRole('link', { name: /log in here|already have an account/i }).click();

      await expect(page).toHaveURL('/login');
    });
  });

  test.describe('form rendering', () => {
    test('should display the registration form with all sections', async ({ registerPage, page }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Personal Information
      await expect(page.getByText(/personal information/i)).toBeVisible();
      await expect(page.getByLabel(/first name/i)).toBeVisible();
      await expect(page.getByLabel(/surname/i)).toBeVisible();

      // Contact Information
      await expect(page.getByText(/contact information/i)).toBeVisible();
      await expect(page.getByLabel(/email/i)).toBeVisible();
      await expect(page.getByLabel(/phone number/i)).toBeVisible();

      // Location Information
      await expect(page.getByText(/location information/i)).toBeVisible();
      await expect(page.getByLabel(/street address/i)).toBeVisible();
      await expect(page.getByRole('button', { name: /get my location/i })).toBeVisible();

      // Sector selection
      await expect(page.getByLabel(/community\/ward/i)).toBeVisible();

      // Submit button
      await expect(page.getByRole('button', { name: /submit registration/i })).toBeVisible();
    });

    test('should load sectors in the dropdown', async ({ registerPage, page }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Click the sector dropdown
      await page.getByLabel(/community\/ward/i).click();

      // Verify at least one sector option is available
      await expect(page.getByRole('option').first()).toBeVisible();
    });
  });

  test.describe('form validation', () => {
    test('should show validation errors for empty required fields', async ({ registerPage, page }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Try to submit without filling any fields
      await registerPage.submit();

      // Should show validation errors
      await expect(page.getByText(/this field is required/i).first()).toBeVisible();
    });

    test('should show validation error for invalid email', async ({ registerPage, page }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Fill with invalid email
      await page.getByLabel(/email/i).fill('invalid-email');
      await page.getByLabel(/email/i).blur();
      await registerPage.submit();

      await expect(page.getByText(/please enter a valid email/i)).toBeVisible();
    });

    test('should show validation error for invalid phone number', async ({ registerPage, page }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Fill with invalid phone
      await page.getByLabel(/phone number/i).fill('12345');
      await page.getByLabel(/phone number/i).blur();
      await registerPage.submit();

      await expect(page.getByText(/please enter a valid phone number/i)).toBeVisible();
    });

    test('should show location required warning when submitting without location', async ({
      registerPage,
      page,
    }) => {
      await registerPage.goto();
      await registerPage.expectLoaded();

      // Fill all fields except location
      await registerPage.fillPersonalInfo('John', 'Doe');
      await registerPage.fillContactInfo('john.doe@example.com', '+27821234567');
      await registerPage.fillAddress('123 Test Street, Test City');
      await page.getByLabel(/community\/ward/i).click();
      await page.getByRole('option').first().click();

      // Submit without capturing location
      await registerPage.submit();

      // Should show location required warning
      await expect(page.getByText(/please capture your location/i)).toBeVisible();
    });
  });

  test.describe('geolocation', () => {
    test('should capture location when Get My Location is clicked', async ({ registerPage, context }) => {
      // Mock geolocation
      await context.grantPermissions(['geolocation']);
      await context.setGeolocation({ latitude: -26.2041, longitude: 28.0473 });

      await registerPage.goto();
      await registerPage.expectLoaded();

      // Click get location button
      await registerPage.clickGetLocation();

      // Should show location captured
      await registerPage.expectLocationCaptured();
    });

    test('should show error when geolocation fails', async ({ registerPage, page, context }) => {
      // Deny geolocation permission
      await context.clearPermissions();

      await registerPage.goto();
      await registerPage.expectLoaded();

      // Override navigator.geolocation to simulate error
      await page.addInitScript(() => {
        Object.defineProperty(navigator, 'geolocation', {
          value: {
            getCurrentPosition: (
              _success: PositionCallback,
              error?: PositionErrorCallback
            ) => {
              if (error) {
                error({
                  code: 1,
                  message: 'User denied Geolocation',
                  PERMISSION_DENIED: 1,
                  POSITION_UNAVAILABLE: 2,
                  TIMEOUT: 3,
                } as GeolocationPositionError);
              }
            },
          },
          writable: false,
        });
      });

      // Reload to apply the init script
      await page.reload();
      await registerPage.expectLoaded();

      // Click get location button
      await registerPage.clickGetLocation();

      // Should show error message
      await expect(page.getByText(/could not get location/i)).toBeVisible();
    });
  });

  test.describe('successful registration', () => {
    test('should complete registration and show success message', async ({
      registerPage,
      page,
      context,
    }) => {
      // Mock geolocation
      await context.grantPermissions(['geolocation']);
      await context.setGeolocation({ latitude: -26.2041, longitude: 28.0473 });

      // Mock the registration API to return success
      await page.route('**/api/v1/auth/register/web', async (route) => {
        await route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            message: 'Registration successful',
            memberId: 'test-member-id',
          }),
        });
      });

      await registerPage.goto();
      await registerPage.expectLoaded();

      // Fill personal information
      await registerPage.fillPersonalInfo('John', 'Doe');

      // Fill contact information
      await registerPage.fillContactInfo('john.doe@example.com', '+27821234567');

      // Fill address
      await registerPage.fillAddress('123 Test Street, Johannesburg, South Africa');

      // Capture location
      await registerPage.clickGetLocation();
      await registerPage.expectLocationCaptured();

      // Select sector
      await page.getByLabel(/community\/ward/i).click();
      await page.getByRole('option').first().click();

      // Submit
      await registerPage.submit();

      // Should show success message
      await registerPage.expectSuccess();
      await expect(page.getByText(/you will receive an email/i)).toBeVisible();
    });

    test('should show error message when registration fails', async ({
      registerPage,
      page,
      context,
    }) => {
      // Mock geolocation
      await context.grantPermissions(['geolocation']);
      await context.setGeolocation({ latitude: -26.2041, longitude: 28.0473 });

      // Mock the registration API to return error
      await page.route('**/api/v1/auth/register/web', async (route) => {
        await route.fulfill({
          status: 409,
          contentType: 'application/json',
          body: JSON.stringify({
            message: 'Email already registered',
          }),
        });
      });

      await registerPage.goto();
      await registerPage.expectLoaded();

      // Fill all fields
      await registerPage.fillPersonalInfo('John', 'Doe');
      await registerPage.fillContactInfo('existing@example.com', '+27821234567');
      await registerPage.fillAddress('123 Test Street, Johannesburg');

      // Capture location
      await registerPage.clickGetLocation();
      await registerPage.expectLocationCaptured();

      // Select sector
      await page.getByLabel(/community\/ward/i).click();
      await page.getByRole('option').first().click();

      // Submit
      await registerPage.submit();

      // Should show error message
      await expect(page.getByRole('alert')).toBeVisible();
    });
  });

  test.describe('responsive design', () => {
    test('should display properly on mobile viewport', async ({ registerPage, page }) => {
      // Set mobile viewport
      await page.setViewportSize({ width: 375, height: 667 });

      await registerPage.goto();
      await registerPage.expectLoaded();

      // All form elements should still be visible
      await expect(page.getByLabel(/first name/i)).toBeVisible();
      await expect(page.getByLabel(/email/i)).toBeVisible();
      await expect(page.getByRole('button', { name: /submit registration/i })).toBeVisible();
    });
  });
});
