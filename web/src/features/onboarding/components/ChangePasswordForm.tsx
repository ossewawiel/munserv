import { type FC, type FormEvent, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import InputAdornment from '@mui/material/InputAdornment';
import IconButton from '@mui/material/IconButton';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';

import { Button } from '@/components/atoms/Button';
import { Input } from '@/components/atoms/Input';
import { PasswordRequirements } from './PasswordRequirements';
import { validatePassword, isPasswordValid } from '../types';

interface ChangePasswordFormProps {
  onSubmit: (newPassword: string) => void;
  isLoading?: boolean;
  error?: string | null;
}

export const ChangePasswordForm: FC<ChangePasswordFormProps> = ({
  onSubmit,
  isLoading = false,
  error = null,
}) => {
  const { t } = useTranslation();
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [touched, setTouched] = useState({ newPassword: false, confirmPassword: false });

  const passwordValidation = useMemo(() => validatePassword(newPassword), [newPassword]);
  const passwordsMatch = newPassword === confirmPassword;
  const canSubmit = isPasswordValid(passwordValidation) && passwordsMatch && confirmPassword.length > 0;

  const handleSubmit = useCallback(
    (e: FormEvent) => {
      e.preventDefault();
      if (canSubmit) {
        onSubmit(newPassword);
      }
    },
    [canSubmit, newPassword, onSubmit]
  );

  const handleTogglePassword = useCallback(() => {
    setShowPassword((prev) => !prev);
  }, []);

  const handleToggleConfirmPassword = useCallback(() => {
    setShowConfirmPassword((prev) => !prev);
  }, []);

  const confirmPasswordError = useMemo(() => {
    if (!touched.confirmPassword || confirmPassword.length === 0) return undefined;
    if (!passwordsMatch) return t('onboarding.passwordsMustMatch');
    return undefined;
  }, [touched.confirmPassword, confirmPassword.length, passwordsMatch, t]);

  return (
    <Box
      component="form"
      onSubmit={handleSubmit}
      sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}
    >
      {error && (
        <Alert severity="error" variant="outlined">
          {error}
        </Alert>
      )}

      <Box>
        <Input
          label={t('onboarding.newPassword')}
          type={showPassword ? 'text' : 'password'}
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          onBlur={() => setTouched((prev) => ({ ...prev, newPassword: true }))}
          placeholder="••••••••"
          autoComplete="new-password"
          disabled={isLoading}
          slotProps={{
            input: {
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    aria-label="toggle password visibility"
                    onClick={handleTogglePassword}
                    edge="end"
                    size="small"
                  >
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            },
          }}
        />
        <PasswordRequirements validation={passwordValidation} />
      </Box>

      <Input
        label={t('onboarding.confirmPassword')}
        type={showConfirmPassword ? 'text' : 'password'}
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        onBlur={() => setTouched((prev) => ({ ...prev, confirmPassword: true }))}
        error={confirmPasswordError}
        placeholder="••••••••"
        autoComplete="new-password"
        disabled={isLoading}
        slotProps={{
          input: {
            endAdornment: (
              <InputAdornment position="end">
                <IconButton
                  aria-label="toggle confirm password visibility"
                  onClick={handleToggleConfirmPassword}
                  edge="end"
                  size="small"
                >
                  {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                </IconButton>
              </InputAdornment>
            ),
          },
        }}
      />

      <Button
        type="submit"
        fullWidth
        isLoading={isLoading}
        disabled={isLoading || !canSubmit}
      >
        {t('onboarding.changePasswordButton')}
      </Button>
    </Box>
  );
};
