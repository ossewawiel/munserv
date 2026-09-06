import { type FC, type ChangeEvent, useState, useCallback, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { AxiosError } from 'axios';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';
import Typography from '@mui/material/Typography';

import { MainCard } from '@/components/atoms/MainCard';
import { Input } from '@/components/atoms/Input';
import { Button } from '@/components/atoms/Button';
import { Spinner } from '@/components/atoms/Spinner';
import { PodHeaderLockup } from '@/components/molecules/PodHeaderLockup';
import { usePodSettings, useUpdatePodSettings } from '../hooks';
import type { UpdatePodSettingsRequest } from '../types';

// The preview's right column matches the artboard's fixed 392px rail
// (Main.dc.html), expressed as a theme spacing multiple (8px * 49) rather
// than a literal pixel value.
const PREVIEW_COLUMN_SPACING_UNITS = 49;

const NAME_MIN_LENGTH = 2;
const NAME_MAX_LENGTH = 100;
const LOGO_URL_MAX_LENGTH = 500;

interface PodSettingsErrorBody {
  code?: string;
  message?: string;
}

/**
 * Pod Settings section that lets a pod chief rename the pod and set the
 * pod's own logo. The header preview is bound to the saved value from
 * usePodSettings, never the draft, so the client never composes
 * "Munserv Pod " + name itself (see domain/pod.md).
 */
export const PodIdentitySection: FC = () => {
  const { t } = useTranslation();
  const { data, isLoading } = usePodSettings();
  const updateSettings = useUpdatePodSettings();

  const [name, setName] = useState('');
  const [logoUrl, setLogoUrl] = useState('');
  const [justSaved, setJustSaved] = useState(false);
  const initializedRef = useRef(false);

  useEffect(() => {
    if (data && !initializedRef.current) {
      setName(data.name);
      setLogoUrl(data.logoUrl ?? '');
      initializedRef.current = true;
    }
  }, [data]);

  const trimmedName = name.trim();
  const nameTooShort = trimmedName.length < NAME_MIN_LENGTH;
  const nameTooLong = trimmedName.length > NAME_MAX_LENGTH;
  const nameError = nameTooShort
    ? t('podSettings.identity.nameTooShort', 'Pod name must be at least 2 characters.')
    : nameTooLong
      ? t('podSettings.identity.nameTooLong', 'Pod name must be 100 characters or fewer.')
      : undefined;

  const trimmedLogoUrl = logoUrl.trim();
  const logoUrlTooLong = trimmedLogoUrl.length > LOGO_URL_MAX_LENGTH;
  const logoUrlError = logoUrlTooLong
    ? t('podSettings.identity.logoUrlTooLong', 'Logo URL must be 500 characters or fewer.')
    : undefined;

  const serverErrorMessage =
    updateSettings.error instanceof AxiosError
      ? (updateSettings.error.response?.data as PodSettingsErrorBody | undefined)?.message
      : undefined;

  const handleNameChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setJustSaved(false);
    setName(event.target.value);
  }, []);

  const handleLogoUrlChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setJustSaved(false);
    setLogoUrl(event.target.value);
  }, []);

  const handleSave = useCallback(() => {
    // Only the fields the pod chief actually changed: sending name on a
    // logo-only edit would re-mark the pod_name setup step complete for no
    // reason (see backend PodService).
    const request: UpdatePodSettingsRequest = {};
    if (trimmedName !== data?.name) {
      request.name = trimmedName;
    }
    if (trimmedLogoUrl !== (data?.logoUrl ?? '')) {
      request.logoUrl = trimmedLogoUrl;
    }

    updateSettings.mutate(request, {
      onSuccess: (response) => {
        setName(response.name);
        setLogoUrl(response.logoUrl ?? '');
        setJustSaved(true);
      },
    });
  }, [trimmedName, trimmedLogoUrl, data, updateSettings]);

  const saveDisabled = nameTooShort || nameTooLong || logoUrlTooLong || updateSettings.isPending;

  return (
    <MainCard title={t('podSettings.identity.title', 'Pod identity')}>
      {isLoading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <Spinner />
        </Box>
      )}

      {!isLoading && (
        <>
          {serverErrorMessage && (
            <Alert severity="error" sx={{ mb: 2.5 }}>
              {serverErrorMessage}
            </Alert>
          )}

          {justSaved && !updateSettings.isError && data && (
            <Alert severity="success" sx={{ mb: 2.5 }}>
              {t('podSettings.identity.saved', 'Saved. The header now reads “{{displayName}}”.', {
                displayName: data.displayName,
              })}
            </Alert>
          )}

          <Box sx={{ display: 'flex', gap: 3, alignItems: 'flex-start' }}>
            <Box sx={{ flex: '1 1 auto', minWidth: 0, display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <Input
                label={t('podSettings.identity.nameLabel', 'Pod name')}
                value={name}
                onChange={handleNameChange}
                error={nameError}
                helperText={
                  nameError ??
                  t(
                    'podSettings.identity.nameHelper',
                    'Between 2 and 100 characters. Administrators and members see this name.'
                  )
                }
              />
              <Input
                label={t('podSettings.identity.logoUrlLabel', 'Logo URL')}
                value={logoUrl}
                onChange={handleLogoUrlChange}
                error={logoUrlError}
                helperText={
                  logoUrlError ??
                  t(
                    'podSettings.identity.logoUrlHelper',
                    'Direct link to a PNG or SVG image, up to 500 characters. Leave it empty to show the Munserv mark on its own.'
                  )
                }
              />
            </Box>

            <Box
              sx={{
                flexGrow: 0,
                flexShrink: 0,
                flexBasis: (theme) => theme.spacing(PREVIEW_COLUMN_SPACING_UNITS),
              }}
            >
              <Typography
                variant="caption"
                sx={{ fontWeight: 500, letterSpacing: '0.4px', color: 'text.secondary' }}
              >
                {t('podSettings.identity.displayNamePreview', 'Header preview')}
              </Typography>
              <Box
                sx={{
                  mt: 1,
                  p: 2,
                  bgcolor: 'tertiaryLight',
                  border: 1,
                  borderColor: 'divider',
                  borderRadius: 2,
                }}
              >
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    px: 2,
                    py: 1.5,
                    bgcolor: 'background.paper',
                    borderRadius: 0.5,
                  }}
                >
                  <Box
                    component="img"
                    src="/assets/app-mark.png"
                    alt={t('common.appName', 'MunServ Admin')}
                    sx={{ height: 32, width: 32, borderRadius: 0.25 }}
                  />
                  <PodHeaderLockup displayName={data?.displayName ?? ''} logoUrl={data?.logoUrl} />
                </Box>
              </Box>
              <Typography
                variant="caption"
                sx={{ mt: 1, display: 'block', letterSpacing: '0.4px', color: 'text.secondary' }}
              >
                {t(
                  'podSettings.identity.previewHint',
                  'Everyone in this pod sees this in the portal header. It updates once the change is saved.'
                )}
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 2.5 }}>
            <Button
              variant="primary"
              disabled={saveDisabled}
              onClick={handleSave}
              startIcon={
                updateSettings.isPending ? <CircularProgress size={16} color="inherit" /> : undefined
              }
            >
              {t('podSettings.identity.save', 'Save changes')}
            </Button>
          </Box>
        </>
      )}
    </MainCard>
  );
};
