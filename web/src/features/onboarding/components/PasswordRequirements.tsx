import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import CheckIcon from '@mui/icons-material/Check';
import CloseIcon from '@mui/icons-material/Close';

import type { PasswordValidation } from '../types';

interface PasswordRequirementsProps {
  validation: PasswordValidation;
}

interface RequirementItemProps {
  met: boolean;
  label: string;
}

const RequirementItem: FC<RequirementItemProps> = ({ met, label }) => (
  <Box
    sx={{
      display: 'flex',
      alignItems: 'center',
      gap: 1,
      color: met ? 'success.main' : 'text.secondary',
    }}
  >
    {met ? (
      <CheckIcon sx={{ fontSize: 16, color: 'success.main' }} />
    ) : (
      <CloseIcon sx={{ fontSize: 16, color: 'text.disabled' }} />
    )}
    <Typography
      variant="body2"
      sx={{
        color: met ? 'success.main' : 'text.secondary',
        textDecoration: met ? 'none' : 'none',
      }}
    >
      {label}
    </Typography>
  </Box>
);

export const PasswordRequirements: FC<PasswordRequirementsProps> = ({ validation }) => {
  const { t } = useTranslation();

  return (
    <Box sx={{ mt: 1 }}>
      <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
        {t('onboarding.passwordRequirements')}
      </Typography>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
        <RequirementItem
          met={validation.minLength}
          label={t('onboarding.requirements.minLength')}
        />
        <RequirementItem
          met={validation.hasUppercase}
          label={t('onboarding.requirements.uppercase')}
        />
        <RequirementItem
          met={validation.hasLowercase}
          label={t('onboarding.requirements.lowercase')}
        />
        <RequirementItem
          met={validation.hasNumber}
          label={t('onboarding.requirements.number')}
        />
      </Box>
    </Box>
  );
};
