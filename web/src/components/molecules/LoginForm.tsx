import { type FC, type FormEvent, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';

import { Button } from '@/components/atoms/Button';
import { Input } from '@/components/atoms/Input';

interface LoginFormProps {
  onSubmit: (email: string, password: string) => void;
  isLoading?: boolean;
  error?: string | null;
}

export const LoginForm: FC<LoginFormProps> = ({
  onSubmit,
  isLoading = false,
  error = null,
}) => {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [validationErrors, setValidationErrors] = useState<{
    email?: string;
    password?: string;
  }>({});

  const validate = useCallback((): boolean => {
    const errors: { email?: string; password?: string } = {};

    if (!email.trim()) {
      errors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      errors.email = 'Invalid email format';
    }

    if (!password) {
      errors.password = 'Password is required';
    }

    setValidationErrors(errors);
    return Object.keys(errors).length === 0;
  }, [email, password]);

  const handleSubmit = useCallback(
    (e: FormEvent) => {
      e.preventDefault();
      if (validate()) {
        onSubmit(email, password);
      }
    },
    [email, password, validate, onSubmit]
  );

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      {error && (
        <Alert severity="error" variant="outlined">
          {error}
        </Alert>
      )}

      <Input
        label={t('auth.email')}
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={validationErrors.email}
        placeholder="admin@example.com"
        autoComplete="email"
        disabled={isLoading}
      />

      <Input
        label={t('auth.password')}
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={validationErrors.password}
        placeholder="••••••••"
        autoComplete="current-password"
        disabled={isLoading}
      />

      <Button
        type="submit"
        fullWidth
        isLoading={isLoading}
        disabled={isLoading}
      >
        {isLoading ? t('auth.loggingIn') : t('auth.loginButton')}
      </Button>
    </Box>
  );
};
