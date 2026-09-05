import { type FC, useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { Trans, useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';

import { useAuth } from '@/shared/hooks/useAuth';
import { useCurrentSupportGrant } from '@/features/auth/hooks';
import { ADMIN_ROLE_LABELS } from '@/shared/types/admin';

const TICK_MS = 1000;
const WARNING_THRESHOLD_MS = 5 * 60 * 1000;

function formatRemaining(remainingMs: number): string {
  const totalSeconds = Math.floor(remainingMs / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
}

/**
 * Shows the remaining time on the super user's active support grant in the
 * header, counting down to the server-owned, sliding expiry. Refreshes the
 * expiry on route change (real activity) and once when it reaches zero; it
 * never polls (see domain/support-grant.md and the story's "Do not" notes).
 */
export const SupportGrantBanner: FC = () => {
  const { t } = useTranslation();
  const location = useLocation();
  const { supportGrant } = useAuth();
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const interval = setInterval(() => setNow(Date.now()), TICK_MS);
    return () => clearInterval(interval);
  }, []);

  const fallbackExpiresAt = supportGrant?.expiresAt ?? null;
  const fallbackRemainingMs = fallbackExpiresAt
    ? Math.max(0, Date.parse(fallbackExpiresAt) - now)
    : 0;

  const { data } = useCurrentSupportGrant({
    pathname: location.pathname,
    expired: fallbackRemainingMs === 0,
    enabled: !!supportGrant,
  });

  if (!supportGrant) {
    return null;
  }

  const expiresAt = data?.expiresAt ?? supportGrant.expiresAt;
  const remainingMs = Math.max(0, Date.parse(expiresAt) - now);
  const isWarning = remainingMs <= WARNING_THRESHOLD_MS;
  const roleLabel = t(`roles.${supportGrant.grantedRole}`, ADMIN_ROLE_LABELS[supportGrant.grantedRole]);

  const label =
    remainingMs === 0 ? (
      t('supportGrant.expired')
    ) : (
      <Trans
        i18nKey="supportGrant.banner"
        values={{ role: roleLabel, remaining: formatRemaining(remainingMs) }}
        components={{
          time: (
            <Box
              component="span"
              aria-label={t('supportGrant.remainingLabel')}
              sx={{ fontVariantNumeric: 'tabular-nums' }}
            />
          ),
        }}
      />
    );

  return (
    <Chip
      icon={<VerifiedUserIcon sx={{ fontSize: 18, ml: '5px', mr: '-6px' }} />}
      label={label}
      color={isWarning ? 'warning' : undefined}
      sx={{
        mr: 2,
        '& .MuiChip-label': { padding: '0 12px' },
        ...(isWarning
          ? {}
          : { bgcolor: 'primary.light', color: 'primary.dark', '& .MuiChip-icon': { color: 'inherit' } }),
      }}
    />
  );
};
