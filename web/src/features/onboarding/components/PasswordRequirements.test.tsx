import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { PasswordRequirements } from './PasswordRequirements';
import type { PasswordValidation } from '../types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        onboarding: {
          passwordRequirements: 'Password Requirements',
          requirements: {
            minLength: 'At least 8 characters',
            uppercase: 'At least one uppercase letter',
            lowercase: 'At least one lowercase letter',
            number: 'At least one number',
          },
        },
      },
    },
  },
});

const renderWithWrapper = (validation: PasswordValidation) => {
  return render(
    <I18nextProvider i18n={i18n}>
      <PasswordRequirements validation={validation} />
    </I18nextProvider>
  );
};

describe('PasswordRequirements', () => {
  it('should show all requirements as not met when password is empty', () => {
    const validation: PasswordValidation = {
      minLength: false,
      hasUppercase: false,
      hasLowercase: false,
      hasNumber: false,
    };

    renderWithWrapper(validation);

    expect(screen.getByText('At least 8 characters')).toBeInTheDocument();
    expect(screen.getByText('At least one uppercase letter')).toBeInTheDocument();
    expect(screen.getByText('At least one lowercase letter')).toBeInTheDocument();
    expect(screen.getByText('At least one number')).toBeInTheDocument();
  });

  it('should show minLength as met when password has 8+ characters', () => {
    const validation: PasswordValidation = {
      minLength: true,
      hasUppercase: false,
      hasLowercase: true,
      hasNumber: false,
    };

    renderWithWrapper(validation);

    // Check that minLength requirement shows check icon
    const minLengthItem = screen.getByText('At least 8 characters').closest('div');
    expect(minLengthItem).toBeInTheDocument();
    // The presence of a check icon indicates the requirement is met
    expect(minLengthItem?.querySelector('svg[data-testid="CheckIcon"]')).toBeInTheDocument();
  });

  it('should show all requirements as met with valid password', () => {
    const validation: PasswordValidation = {
      minLength: true,
      hasUppercase: true,
      hasLowercase: true,
      hasNumber: true,
    };

    renderWithWrapper(validation);

    // All items should have check icons - 4 check icons for 4 requirements
    const checkIcons = document.querySelectorAll('svg[data-testid="CheckIcon"]');
    expect(checkIcons).toHaveLength(4);
  });

  it('should display password requirements header', () => {
    const validation: PasswordValidation = {
      minLength: false,
      hasUppercase: false,
      hasLowercase: false,
      hasNumber: false,
    };

    renderWithWrapper(validation);

    expect(screen.getByText('Password Requirements')).toBeInTheDocument();
  });
});
