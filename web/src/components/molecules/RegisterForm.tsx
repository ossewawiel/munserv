import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useForm, Controller } from 'react-hook-form';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Alert from '@mui/material/Alert';
import Typography from '@mui/material/Typography';
import LocationOnIcon from '@mui/icons-material/LocationOn';

import { Button } from '@/components/atoms/Button';
import type { Sector } from '@/features/auth/types';

export interface RegisterFormData {
  email: string;
  firstName: string;
  surname: string;
  phone: string;
  address: string;
  latitude: number;
  longitude: number;
  sectorId: string;
}

interface RegisterFormProps {
  sectors: Sector[];
  onSubmit: (data: RegisterFormData) => void;
  isLoading?: boolean;
  error?: string;
}

export const RegisterForm: FC<RegisterFormProps> = ({
  sectors,
  onSubmit,
  isLoading = false,
  error,
}) => {
  const { t } = useTranslation();
  const [locationStatus, setLocationStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  const {
    control,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<RegisterFormData>({
    defaultValues: {
      email: '',
      firstName: '',
      surname: '',
      phone: '',
      address: '',
      latitude: 0,
      longitude: 0,
      sectorId: '',
    },
  });

  const latitude = watch('latitude');
  const longitude = watch('longitude');
  const hasLocation = latitude !== 0 && longitude !== 0;

  const handleGetLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setLocationStatus('error');
      return;
    }

    setLocationStatus('loading');
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setValue('latitude', position.coords.latitude);
        setValue('longitude', position.coords.longitude);
        setLocationStatus('success');
      },
      () => {
        setLocationStatus('error');
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }, [setValue]);

  const onFormSubmit = useCallback(
    (data: RegisterFormData) => {
      onSubmit(data);
    },
    [onSubmit]
  );

  const getLocationButtonText = () => {
    if (locationStatus === 'loading') return t('auth.gettingLocation');
    if (locationStatus === 'success') return t('auth.locationCaptured');
    return t('auth.getLocation');
  };

  return (
    <Box
      component="form"
      onSubmit={handleSubmit(onFormSubmit)}
      sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}
    >
      {error && (
        <Alert severity="error" sx={{ mb: 1 }}>
          {error}
        </Alert>
      )}

      {/* Personal Information Section */}
      <Typography variant="subtitle2" color="text.secondary">
        {t('auth.personalInfo')}
      </Typography>

      <Box sx={{ display: 'flex', gap: 2 }}>
        <Controller
          name="firstName"
          control={control}
          rules={{
            required: t('validation.required'),
            maxLength: { value: 50, message: t('validation.maxLength', { max: 50 }) },
          }}
          render={({ field }) => (
            <TextField
              {...field}
              label={t('auth.firstName')}
              error={!!errors.firstName}
              helperText={errors.firstName?.message}
              disabled={isLoading}
              fullWidth
              size="small"
            />
          )}
        />
        <Controller
          name="surname"
          control={control}
          rules={{
            required: t('validation.required'),
            maxLength: { value: 50, message: t('validation.maxLength', { max: 50 }) },
          }}
          render={({ field }) => (
            <TextField
              {...field}
              label={t('auth.surname')}
              error={!!errors.surname}
              helperText={errors.surname?.message}
              disabled={isLoading}
              fullWidth
              size="small"
            />
          )}
        />
      </Box>

      {/* Contact Information Section */}
      <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 1 }}>
        {t('auth.contactInfo')}
      </Typography>

      <Controller
        name="email"
        control={control}
        rules={{
          required: t('validation.required'),
          pattern: {
            value: /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/,
            message: t('validation.invalidEmail'),
          },
        }}
        render={({ field }) => (
          <TextField
            {...field}
            type="email"
            label={t('auth.email')}
            error={!!errors.email}
            helperText={errors.email?.message || t('auth.emailHelp')}
            disabled={isLoading}
            fullWidth
            size="small"
          />
        )}
      />

      <Controller
        name="phone"
        control={control}
        rules={{
          required: t('validation.required'),
          pattern: {
            value: /^\+?[0-9]{10,15}$/,
            message: t('validation.invalidPhone'),
          },
        }}
        render={({ field }) => (
          <TextField
            {...field}
            type="tel"
            label={t('auth.phone')}
            placeholder="+27821234567"
            error={!!errors.phone}
            helperText={errors.phone?.message || t('auth.phoneHelp')}
            disabled={isLoading}
            fullWidth
            size="small"
          />
        )}
      />

      {/* Location Section */}
      <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 1 }}>
        {t('auth.locationInfo')}
      </Typography>

      <Controller
        name="address"
        control={control}
        rules={{
          required: t('validation.required'),
          maxLength: { value: 500, message: t('validation.maxLength', { max: 500 }) },
        }}
        render={({ field }) => (
          <TextField
            {...field}
            label={t('auth.address')}
            error={!!errors.address}
            helperText={errors.address?.message}
            disabled={isLoading}
            multiline
            rows={2}
            fullWidth
            size="small"
          />
        )}
      />

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <Button
          type="button"
          variant="secondary"
          onClick={handleGetLocation}
          disabled={isLoading || locationStatus === 'loading'}
          startIcon={<LocationOnIcon />}
          sx={{ whiteSpace: 'nowrap' }}
        >
          {getLocationButtonText()}
        </Button>
        {locationStatus === 'error' && (
          <Typography variant="caption" color="error">
            {t('auth.locationError')}
          </Typography>
        )}
      </Box>

      {/* Hidden location fields - validated on submit */}
      <Controller
        name="latitude"
        control={control}
        rules={{
          validate: (value) => value !== 0 || t('auth.locationRequired'),
        }}
        render={({ field }) => <input type="hidden" {...field} />}
      />
      <Controller
        name="longitude"
        control={control}
        rules={{
          validate: (value) => value !== 0 || t('auth.locationRequired'),
        }}
        render={({ field }) => <input type="hidden" {...field} />}
      />

      {/* Sector Selection */}
      <Controller
        name="sectorId"
        control={control}
        rules={{ required: t('validation.required') }}
        render={({ field }) => (
          <TextField
            {...field}
            select
            label={t('auth.sector')}
            error={!!errors.sectorId}
            helperText={errors.sectorId?.message || t('auth.sectorHelp')}
            disabled={isLoading || sectors.length === 0}
            fullWidth
            size="small"
          >
            {sectors.map((sector) => (
              <MenuItem key={sector.id} value={sector.id}>
                {sector.name}
              </MenuItem>
            ))}
          </TextField>
        )}
      />

      {!hasLocation && (errors.latitude || errors.longitude) && (
        <Alert severity="warning">
          {t('auth.locationRequired')}
        </Alert>
      )}

      <Button
        type="submit"
        variant="primary"
        size="large"
        isLoading={isLoading}
        disabled={isLoading}
        fullWidth
        sx={{ mt: 2 }}
      >
        {t('auth.submitRegistration')}
      </Button>
    </Box>
  );
};

export default RegisterForm;
