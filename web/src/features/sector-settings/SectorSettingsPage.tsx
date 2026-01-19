import { type FC, useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useForm, Controller } from 'react-hook-form';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Divider from '@mui/material/Divider';
import FormControl from '@mui/material/FormControl';
import FormHelperText from '@mui/material/FormHelperText';
import Grid from '@mui/material/Grid';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import Skeleton from '@mui/material/Skeleton';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import SaveIcon from '@mui/icons-material/Save';
import SettingsIcon from '@mui/icons-material/Settings';
import ScheduleIcon from '@mui/icons-material/Schedule';
import GroupIcon from '@mui/icons-material/Group';
import WarningIcon from '@mui/icons-material/Warning';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { useSectorSettings, useUpdateSectorSettings } from './hooks';
import { useGroundAdmins } from '@/features/ground-admins/hooks';
import type { SectorSettingsUpdate, VerificationMode } from '@/shared/types/sectorSettings';
import { VERIFICATION_MODES, VERIFICATION_MODE_LABELS } from '@/shared/types/sectorSettings';

interface FormData {
  newIssueVerificationMode: VerificationMode;
  fixVerificationMode: VerificationMode;
  daysFixedBeforeClosed: number;
  minimumGroundAdmins: number;
}

/**
 * Sector Settings page for Sector Chiefs
 */
export const SectorSettingsPage: FC = () => {
  const { t } = useTranslation();

  // Queries
  const { data: settings, isLoading, error } = useSectorSettings();
  const { data: groundAdminsData } = useGroundAdmins('active');

  // Mutations
  const updateSettings = useUpdateSectorSettings();

  // Form
  const {
    control,
    handleSubmit,
    reset,
    watch,
    formState: { isDirty },
  } = useForm<FormData>({
    defaultValues: {
      newIssueVerificationMode: 'all_notified',
      fixVerificationMode: 'all_notified',
      daysFixedBeforeClosed: 7,
      minimumGroundAdmins: 2,
    },
  });

  // Watch minimum for warning
  const minimumGroundAdmins = watch('minimumGroundAdmins');
  const activeGroundAdminsCount = groundAdminsData?.items?.length ?? 0;
  const isBelowMinimum = activeGroundAdminsCount < minimumGroundAdmins;

  // Update form when settings load
  useEffect(() => {
    if (settings) {
      reset({
        newIssueVerificationMode: settings.newIssueVerificationMode,
        fixVerificationMode: settings.fixVerificationMode,
        daysFixedBeforeClosed: settings.daysFixedBeforeClosed,
        minimumGroundAdmins: settings.minimumGroundAdmins,
      });
    }
  }, [settings, reset]);

  const onSubmit = useCallback(
    (data: FormData) => {
      const update: SectorSettingsUpdate = {
        newIssueVerificationMode: data.newIssueVerificationMode,
        fixVerificationMode: data.fixVerificationMode,
        daysFixedBeforeClosed: data.daysFixedBeforeClosed,
        minimumGroundAdmins: data.minimumGroundAdmins,
      };
      updateSettings.mutate(update);
    },
    [updateSettings]
  );

  if (isLoading) {
    return (
      <DashboardLayout>
        <Breadcrumbs
          title={t('sectorSettings.title', 'Sector Settings')}
          items={[
            { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
            { label: t('sectorSettings.title', 'Sector Settings') },
          ]}
        />
        <Card sx={{ mt: 3 }}>
          <CardContent>
            <Stack spacing={2}>
              <Skeleton variant="rectangular" height={56} />
              <Skeleton variant="rectangular" height={56} />
              <Skeleton variant="rectangular" height={56} />
              <Skeleton variant="rectangular" height={56} />
            </Stack>
          </CardContent>
        </Card>
      </DashboardLayout>
    );
  }

  if (error) {
    return (
      <DashboardLayout>
        <Breadcrumbs
          title={t('sectorSettings.title', 'Sector Settings')}
          items={[
            { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
            { label: t('sectorSettings.title', 'Sector Settings') },
          ]}
        />
        <Alert severity="error" sx={{ mt: 3 }}>
          {t('errors.loadFailed', 'Failed to load settings')}
        </Alert>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('sectorSettings.title', 'Sector Settings')}
        subtitle={t(
          'sectorSettings.subtitle',
          'Configure Ground Admin verification and issue lifecycle settings'
        )}
        items={[
          { label: t('dashboard.title', 'Dashboard'), path: '/', icon: 'home' },
          { label: t('sectorSettings.title', 'Sector Settings') },
        ]}
      />

      <Box component="form" onSubmit={handleSubmit(onSubmit)} sx={{ mt: 3 }}>
        <Grid container spacing={3}>
          {/* Verification Settings */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Card>
              <CardHeader
                avatar={<SettingsIcon color="primary" />}
                title={t('sectorSettings.verificationSettings', 'Verification Settings')}
                subheader={t(
                  'sectorSettings.verificationDescription',
                  'Configure how Ground Admins are notified for verification tasks'
                )}
              />
              <Divider />
              <CardContent>
                <Stack spacing={3}>
                  <Controller
                    name="newIssueVerificationMode"
                    control={control}
                    render={({ field }) => (
                      <FormControl fullWidth>
                        <InputLabel>
                          {t('sectorSettings.newIssueMode', 'New Issue Verification Mode')}
                        </InputLabel>
                        <Select
                          {...field}
                          label={t('sectorSettings.newIssueMode', 'New Issue Verification Mode')}
                        >
                          {VERIFICATION_MODES.map((mode) => (
                            <MenuItem key={mode} value={mode}>
                              {t(VERIFICATION_MODE_LABELS[mode], mode)}
                            </MenuItem>
                          ))}
                        </Select>
                        <FormHelperText>
                          {t(
                            'sectorSettings.newIssueModeHelp',
                            'How Ground Admins are notified when a new issue needs verification'
                          )}
                        </FormHelperText>
                      </FormControl>
                    )}
                  />

                  <Controller
                    name="fixVerificationMode"
                    control={control}
                    render={({ field }) => (
                      <FormControl fullWidth>
                        <InputLabel>
                          {t('sectorSettings.fixMode', 'Fix Verification Mode')}
                        </InputLabel>
                        <Select
                          {...field}
                          label={t('sectorSettings.fixMode', 'Fix Verification Mode')}
                        >
                          {VERIFICATION_MODES.map((mode) => (
                            <MenuItem key={mode} value={mode}>
                              {t(VERIFICATION_MODE_LABELS[mode], mode)}
                            </MenuItem>
                          ))}
                        </Select>
                        <FormHelperText>
                          {t(
                            'sectorSettings.fixModeHelp',
                            'How Ground Admins are notified when a fix needs verification'
                          )}
                        </FormHelperText>
                      </FormControl>
                    )}
                  />
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          {/* Issue Lifecycle */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Card>
              <CardHeader
                avatar={<ScheduleIcon color="primary" />}
                title={t('sectorSettings.lifecycle', 'Issue Lifecycle')}
                subheader={t(
                  'sectorSettings.lifecycleDescription',
                  'Configure automatic issue state transitions'
                )}
              />
              <Divider />
              <CardContent>
                <Controller
                  name="daysFixedBeforeClosed"
                  control={control}
                  rules={{
                    min: { value: 1, message: t('common.validation.min', 'Minimum value is 1') },
                    max: { value: 90, message: t('common.validation.max', 'Maximum value is 90') },
                  }}
                  render={({ field, fieldState }) => (
                    <TextField
                      {...field}
                      type="number"
                      fullWidth
                      label={t('sectorSettings.daysBeforeClosed', 'Days before fixed issues close')}
                      error={!!fieldState.error}
                      helperText={
                        fieldState.error?.message ||
                        t(
                          'sectorSettings.daysBeforeClosedHelp',
                          'Issues in FIXED state will automatically move to CLOSED after this many days'
                        )
                      }
                      inputProps={{ min: 1, max: 90 }}
                      onChange={(e) => field.onChange(Number(e.target.value))}
                    />
                  )}
                />
              </CardContent>
            </Card>
          </Grid>

          {/* Ground Admin Management */}
          <Grid size={{ xs: 12 }}>
            <Card>
              <CardHeader
                avatar={<GroupIcon color="primary" />}
                title={t('sectorSettings.groundAdminManagement', 'Ground Admin Management')}
                subheader={t(
                  'sectorSettings.groundAdminDescription',
                  'Configure Ground Admin requirements for your sector'
                )}
              />
              <Divider />
              <CardContent>
                <Grid container spacing={3} alignItems="center">
                  <Grid size={{ xs: 12, md: 6 }}>
                    <Controller
                      name="minimumGroundAdmins"
                      control={control}
                      rules={{
                        min: { value: 0, message: t('common.validation.min', 'Minimum value is 0') },
                        max: { value: 50, message: t('common.validation.max', 'Maximum value is 50') },
                      }}
                      render={({ field, fieldState }) => (
                        <TextField
                          {...field}
                          type="number"
                          fullWidth
                          label={t('sectorSettings.minimumGroundAdmins', 'Minimum Ground Admins')}
                          error={!!fieldState.error}
                          helperText={
                            fieldState.error?.message ||
                            t(
                              'sectorSettings.minimumGroundAdminsHelp',
                              'You will see a warning if the number of active Ground Admins falls below this threshold'
                            )
                          }
                          inputProps={{ min: 0, max: 50 }}
                          onChange={(e) => field.onChange(Number(e.target.value))}
                        />
                      )}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <Box
                      sx={{
                        p: 2,
                        bgcolor: isBelowMinimum ? 'warning.lighter' : 'success.lighter',
                        borderRadius: 1,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 1,
                      }}
                    >
                      {isBelowMinimum ? (
                        <>
                          <WarningIcon color="warning" />
                          <Box>
                            <Typography
                              variant="body2"
                              fontWeight={600}
                              color="warning.dark"
                            >
                              {t('sectorSettings.belowMinimum', 'Below minimum')}
                            </Typography>
                            <Typography variant="caption" color="warning.dark">
                              {t(
                                'sectorSettings.belowMinimumDescription',
                                'You have {{current}} active Ground Admins, minimum is {{minimum}}',
                                {
                                  current: activeGroundAdminsCount,
                                  minimum: minimumGroundAdmins,
                                }
                              )}
                            </Typography>
                          </Box>
                        </>
                      ) : (
                        <>
                          <GroupIcon color="success" />
                          <Box>
                            <Typography
                              variant="body2"
                              fontWeight={600}
                              color="success.dark"
                            >
                              {t('sectorSettings.atOrAboveMinimum', 'Requirement met')}
                            </Typography>
                            <Typography variant="caption" color="success.dark">
                              {t(
                                'sectorSettings.currentGroundAdmins',
                                '{{count}} active Ground Admins',
                                { count: activeGroundAdminsCount }
                              )}
                            </Typography>
                          </Box>
                        </>
                      )}
                    </Box>
                  </Grid>
                </Grid>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Save Button */}
        <Box sx={{ mt: 3, display: 'flex', justifyContent: 'flex-end' }}>
          <Button
            type="submit"
            variant="contained"
            startIcon={<SaveIcon />}
            disabled={!isDirty || updateSettings.isPending}
          >
            {updateSettings.isPending
              ? t('common.saving', 'Saving...')
              : t('common.buttons.save', 'Save Changes')}
          </Button>
        </Box>

        {/* Success/Error Messages */}
        {updateSettings.isSuccess && (
          <Alert severity="success" sx={{ mt: 2 }}>
            {t('sectorSettings.saveSuccess', 'Settings saved successfully')}
          </Alert>
        )}
        {updateSettings.isError && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {t('sectorSettings.saveError', 'Failed to save settings')}
          </Alert>
        )}
      </Box>
    </DashboardLayout>
  );
};
