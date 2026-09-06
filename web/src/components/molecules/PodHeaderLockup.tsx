import { type FC } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

interface PodHeaderLockupProps {
  /** Server-derived "Munserv Pod {name}"; never composed on the client (domain/pod.md). */
  displayName: string;
  /** The pod's own logo, if configured. Null/undefined renders the name on its own. */
  logoUrl?: string | null;
}

/**
 * The pod chief's branding lockup: the pod's own logo, if set, then the
 * server-derived displayName. Used both in the portal header
 * (`DashboardLayout`) and in the Pod Settings "Header preview"
 * (`PodIdentitySection`) so the two renders cannot drift.
 */
export const PodHeaderLockup: FC<PodHeaderLockupProps> = ({ displayName, logoUrl }) => (
  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, ml: 5 }}>
    {logoUrl && (
      <Box component="img" src={logoUrl} alt="" sx={{ height: 32, width: 32, borderRadius: 1 }} />
    )}
    <Typography
      sx={{
        fontSize: 16,
        lineHeight: 1.5,
        fontWeight: 600,
        letterSpacing: '0.15px',
        color: 'primary.main',
        whiteSpace: 'nowrap',
      }}
    >
      {displayName}
    </Typography>
  </Box>
);
