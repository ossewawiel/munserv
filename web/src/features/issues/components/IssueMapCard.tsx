import { type FC, useMemo, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Tooltip, useMap } from 'react-leaflet';
import L from 'leaflet';
import Paper from '@mui/material/Paper';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { HeatBadge } from '@/components/molecules/HeatIndicator';
import { issueTypeColors } from '@/theme/colors';
import type { IssueSummary, IssueType } from '../types';

import 'leaflet/dist/leaflet.css';

// Fix for default marker icon in Leaflet with bundlers
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

// Fix Leaflet's default icon path issue
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
});

// Create colored marker icon
function createColoredIcon(color: string): L.DivIcon {
  return L.divIcon({
    className: 'custom-marker',
    html: `
      <svg width="25" height="41" viewBox="0 0 25 41" xmlns="http://www.w3.org/2000/svg">
        <path fill="${color}" stroke="#fff" stroke-width="1" d="M12.5 0C5.596 0 0 5.596 0 12.5c0 7.97 11.25 27.5 12.5 28.5 1.25-1 12.5-20.53 12.5-28.5C25 5.596 19.404 0 12.5 0z"/>
        <circle fill="#fff" cx="12.5" cy="12.5" r="5"/>
      </svg>
    `,
    iconSize: [25, 41],
    iconAnchor: [12.5, 41],
    popupAnchor: [0, -41],
  });
}

// Memoize icons per type
const markerIcons: Record<IssueType, L.DivIcon> = {
  pothole: createColoredIcon(issueTypeColors.pothole),
  water_leak: createColoredIcon(issueTypeColors.water_leak),
  sewage_leak: createColoredIcon(issueTypeColors.sewage_leak),
  traffic_light: createColoredIcon(issueTypeColors.traffic_light),
  street_light: createColoredIcon(issueTypeColors.street_light),
  illegal_dumping: createColoredIcon(issueTypeColors.illegal_dumping),
  other: createColoredIcon(issueTypeColors.other),
};

// Auto-fit bounds component
const FitBounds: FC<{ issues: IssueSummary[] }> = ({ issues }) => {
  const map = useMap();

  useEffect(() => {
    if (issues.length > 0) {
      const bounds = L.latLngBounds(
        issues.map((issue) => [issue.location.latitude, issue.location.longitude])
      );
      map.fitBounds(bounds, { padding: [50, 50] });
    }
  }, [map, issues]);

  return null;
};

// Default center (Johannesburg)
const DEFAULT_CENTER: [number, number] = [-26.2041, 28.0473];

interface IssueMapCardProps {
  issues: IssueSummary[];
}

export const IssueMapCard: FC<IssueMapCardProps> = ({ issues }) => {
  const center = useMemo(() => {
    if (issues.length === 0) return DEFAULT_CENTER;
    const avgLat = issues.reduce((sum, i) => sum + i.location.latitude, 0) / issues.length;
    const avgLng = issues.reduce((sum, i) => sum + i.location.longitude, 0) / issues.length;
    return [avgLat, avgLng] as [number, number];
  }, [issues]);

  return (
    <Paper
      elevation={0}
      sx={{
        flex: 1,
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
        overflow: 'hidden',
        minHeight: 400,
      }}
    >
      <MapContainer
        center={center}
        zoom={12}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <FitBounds issues={issues} />
        {issues.map((issue) => (
          <Marker
            key={issue.id}
            position={[issue.location.latitude, issue.location.longitude]}
            icon={markerIcons[issue.type]}
          >
            <Tooltip direction="top" offset={[0, -35]} opacity={1}>
              <Box sx={{ minWidth: 150, p: 0.5 }}>
                <IssueTypeBadge type={issue.type} size="sm" />
                <Box sx={{ mt: 1, display: 'flex', gap: 1, alignItems: 'center' }}>
                  <IssueStateBadge state={issue.state} />
                  <HeatBadge heat={issue.heat} />
                </Box>
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  {new Date(issue.createdAt).toLocaleDateString()}
                </Typography>
              </Box>
            </Tooltip>
          </Marker>
        ))}
      </MapContainer>
    </Paper>
  );
};
