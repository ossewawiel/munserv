import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { AxiosError, AxiosHeaders } from 'axios';
import { CreatePodAdminDialog } from './CreatePodAdminDialog';

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'podAdministrators.addNew': 'Add Administrator',
        'podAdministrators.form.email': 'Email Address',
        'podAdministrators.form.displayName': 'Display Name',
        'podAdministrators.form.role': 'Role',
        'podAdministrators.form.emailRequired': 'Email is required',
        'podAdministrators.form.emailInvalid': 'Invalid email format',
        'podAdministrators.form.displayNameRequired': 'Display name is required',
        'podAdministrators.errors.emailExists':
          'An administrator with this email already exists',
        'podAdministrators.errors.createFailed': 'Failed to create administrator',
        'common.cancel': 'Cancel',
        'common.loading': 'Loading...',
      };
      return translations[key] ?? key;
    },
  }),
}));

// The endpoint's error body is the flat shape declared by
// com.munserv.pod.api.PodController.ErrorResponse ({ code, message }),
// which PodAdministratorController resolves to unqualified. See
// PodAdministratorControllerTest.kt asserting `$.code`, not `$.error.code`.
function createConflictError(): AxiosError {
  return new AxiosError('Request failed with status code 409', 'ERR_BAD_REQUEST', undefined, undefined, {
    status: 409,
    statusText: 'Conflict',
    headers: new AxiosHeaders(),
    config: { headers: new AxiosHeaders() },
    data: { code: 'email_exists', message: 'Email admin@example.com is already registered' },
  });
}

function createValidationError(message: string): AxiosError {
  return new AxiosError('Request failed with status code 400', 'ERR_BAD_REQUEST', undefined, undefined, {
    status: 400,
    statusText: 'Bad Request',
    headers: new AxiosHeaders(),
    config: { headers: new AxiosHeaders() },
    data: { code: 'validation_error', message },
  });
}

function fillRequiredFields(email: string, displayName: string) {
  fireEvent.change(screen.getByLabelText(/email address/i), { target: { value: email } });
  fireEvent.change(screen.getByLabelText(/display name/i), { target: { value: displayName } });
}

describe('CreatePodAdminDialog', () => {
  it('should show the duplicate email error and keep the dialog open with the entered values', () => {
    const onSubmit = vi.fn();
    const { rerender } = render(
      <CreatePodAdminDialog open onClose={vi.fn()} onSubmit={onSubmit} isLoading={false} />
    );

    fillRequiredFields('admin@example.com', 'New Admin');
    fireEvent.click(screen.getByRole('button', { name: /add administrator/i }));
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'admin@example.com', displayName: 'New Admin' })
    );

    // Simulate the mutation coming back with the backend's 409.
    rerender(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={onSubmit}
        isLoading={false}
        error={createConflictError()}
      />
    );

    expect(
      screen.getByText(/an administrator with this email already exists/i)
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/email address/i)).toHaveValue('admin@example.com');
    expect(screen.getByLabelText(/display name/i)).toHaveValue('New Admin');
  });

  it('should show a form-level alert with the server message for a non-conflict 4xx error', () => {
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={vi.fn()}
        isLoading={false}
        error={createValidationError('Display name is required')}
      />
    );

    expect(screen.getByText('Display name is required')).toBeInTheDocument();
    expect(
      screen.queryByText(/an administrator with this email already exists/i)
    ).not.toBeInTheDocument();
  });

  it('should clear the form-level alert when any field is edited', () => {
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={vi.fn()}
        isLoading={false}
        error={createValidationError('Display name is required')}
      />
    );

    expect(screen.getByText('Display name is required')).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/display name/i), { target: { value: 'Fixed Name' } });

    expect(screen.queryByText('Display name is required')).not.toBeInTheDocument();
  });

  it('should show the generic failure alert for a network error with no response', () => {
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={vi.fn()}
        isLoading={false}
        error={new Error('Network Error')}
      />
    );

    expect(screen.getByText('Failed to create administrator')).toBeInTheDocument();
  });

  it('should allow resubmitting after correcting the email', () => {
    const onSubmit = vi.fn();
    render(
      <CreatePodAdminDialog
        open
        onClose={vi.fn()}
        onSubmit={onSubmit}
        isLoading={false}
        error={createConflictError()}
      />
    );

    expect(
      screen.getByText(/an administrator with this email already exists/i)
    ).toBeInTheDocument();

    fillRequiredFields('new-admin@example.com', 'New Admin');

    expect(
      screen.queryByText(/an administrator with this email already exists/i)
    ).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /add administrator/i }));

    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'new-admin@example.com', displayName: 'New Admin' })
    );
  });
});
