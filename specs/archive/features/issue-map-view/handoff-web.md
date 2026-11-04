# Handoff: Web - Issue Map View

## Context

Add a map view accessible from the Issues list that displays all active issues on an interactive map. Users can filter pins by issue type using toggle buttons.

## Files to Create/Modify

### Create
1. `web/src/components/atoms/IssueTypeFilterButton.tsx`
2. `web/src/components/molecules/IssueTypeFilterBar.tsx`
3. `web/src/features/issues/components/IssueMapCard.tsx`
4. `web/src/features/issues/IssueMapPage.tsx`

### Modify
1. `web/src/theme/colors.ts` - Add issueTypeColors
2. `web/src/App.tsx` - Add route
3. `web/src/features/issues/IssuesPage.tsx` - Add Map button
4. `web/src/features/issues/hooks.ts` - Add useIssuesForMap
5. `web/src/features/issues/api.ts` - Add getAllForMap
6. `web/src/locales/en/translation.json` - Add i18n keys

---

## Implementation Steps

### Step 1: Add Issue Type Colors

**File:** `web/src/theme/colors.ts`

Add after `heatColors`:

```typescript
// Issue type colors for map pins and filter buttons
export const issueTypeColors = {
  pothole: '#795548',         // Brown
  water_leak: '#2196F3',      // Blue
  sewage_leak: '#4CAF50',     // Green
  traffic_light: '#F44336',   // Red
  street_light: '#FFC107',    // Amber
  illegal_dumping: '#9C27B0', // Purple
  other: '#9E9E9E',           // Gray
} as const;

export type IssueTypeColor = keyof typeof issueTypeColors;
```

### Step 2: Create IssueTypeFilterButton

**File:** `web/src/components/atoms/IssueTypeFilterButton.tsx`

```typescript
import { type FC } from 'react';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import SvgIcon from '@mui/material/SvgIcon';
import { useTranslation } from 'react-i18next';
import { alpha } from '@mui/material/styles';

import type { IssueType } from '@/features/issues/types';
import { issueTypeColors } from '@/theme/colors';

// Same icons as IssueTypeBadge
const typeIcons: Record<IssueType, string> = {
  pothole: 'M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z',
  water_leak: 'M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707',
  sewage_leak: 'M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z',
  traffic_light: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h10a2 2 0 012 2v14a2 2 0 01-2 2z',
  street_light: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z',
  illegal_dumping: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16',
  other: 'M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
};

interface IssueTypeFilterButtonProps {
  type: IssueType;
  isActive: boolean;
  onClick: () => void;
}

export const IssueTypeFilterButton: FC<IssueTypeFilterButtonProps> = ({
  type,
  isActive,
  onClick,
}) => {
  const { t } = useTranslation();
  const color = issueTypeColors[type];

  return (
    <Tooltip title={t(`issues.types.${type}`)} placement="left">
      <IconButton
        onClick={onClick}
        sx={{
          width: 40,
          height: 40,
          borderRadius: '50%',
          transition: 'all 0.2s ease-in-out',
          ...(isActive
            ? {
                bgcolor: color,
                color: 'white',
                '&:hover': {
                  bgcolor: color,
                  opacity: 0.9,
                },
              }
            : {
                bgcolor: alpha(color, 0.15),
                color: color,
                '&:hover': {
                  bgcolor: alpha(color, 0.25),
                },
              }),
        }}
      >
        <SvgIcon viewBox="0 0 24 24" sx={{ fontSize: 20 }}>
          <path
            fill="none"
            stroke="currentColor"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d={typeIcons[type]}
          />
        </SvgIcon>
      </IconButton>
    </Tooltip>
  );
};
```

### Step 3: Create IssueTypeFilterBar

**File:** `web/src/components/molecules/IssueTypeFilterBar.tsx`

```typescript
import { type FC, useCallback } from 'react';
import Stack from '@mui/material/Stack';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';

import { IssueTypeFilterButton } from '@/components/atoms/IssueTypeFilterButton';
import type { IssueType } from '@/features/issues/types';

const ALL_ISSUE_TYPES: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

interface IssueTypeFilterBarProps {
  activeTypes: Set<IssueType>;
  onToggle: (type: IssueType) => void;
}

export const IssueTypeFilterBar: FC<IssueTypeFilterBarProps> = ({
  activeTypes,
  onToggle,
}) => {
  const { t } = useTranslation();

  const handleToggle = useCallback(
    (type: IssueType) => () => onToggle(type),
    [onToggle]
  );

  return (
    <Paper
      elevation={0}
      sx={{
        p: 1.5,
        border: 1,
        borderColor: 'divider',
        borderRadius: 2,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 1,
      }}
    >
      <Typography
        variant="caption"
        color="text.secondary"
        sx={{ mb: 0.5, writingMode: 'vertical-rl', textOrientation: 'mixed' }}
      >
        {t('issues.map.filterByType')}
      </Typography>
      <Stack direction="column" spacing={1}>
        {ALL_ISSUE_TYPES.map((type) => (
          <IssueTypeFilterButton
            key={type}
            type={type}
            isActive={activeTypes.has(type)}
            onClick={handleToggle(type)}
          />
        ))}
      </Stack>
    </Paper>
  );
};
```

### Step 4: Add API and Hook

**File:** `web/src/features/issues/api.ts`

Add to `issueApi` object:

```typescript
getAllForMap: () =>
  apiClient
    .get<{ items: IssueSummary[]; pagination: PaginationMeta }>('/v1/issues', {
      params: { limit: 1000 },
    })
    .then((r) => r.data.items),
```

**File:** `web/src/features/issues/hooks.ts`

Add hook:

```typescript
export function useIssuesForMap() {
  return useQuery({
    queryKey: ['issues', 'map'],
    queryFn: () => issueApi.getAllForMap(),
    staleTime: 30000, // 30 seconds
  });
}
```

### Step 5: Create IssueMapCard

**File:** `web/src/features/issues/components/IssueMapCard.tsx`

```typescript
import { type FC, useMemo, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import Paper from '@mui/material/Paper';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';

import { IssueTypeBadge } from '@/components/molecules/IssueTypeBadge';
import { IssueStateBadge } from '@/components/molecules/IssueStateBadge';
import { HeatBadge } from '@/components/molecules/HeatIndicator';
import { issueTypeColors } from '@/theme/colors';
import type { IssueSummary } from '../types';
import type { IssueType } from '../types';

import 'leaflet/dist/leaflet.css';

// Fix default marker icons
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

delete (L.Icon.Default.prototype as unknown as { _getIconUrl?: unknown })._getIconUrl;
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

interface IssueMapCardProps {
  issues: IssueSummary[];
}

export const IssueMapCard: FC<IssueMapCardProps> = ({ issues }) => {
  const { t } = useTranslation();

  // Default center (Johannesburg)
  const defaultCenter: [number, number] = [-26.2041, 28.0473];

  const center = useMemo(() => {
    if (issues.length === 0) return defaultCenter;
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
            <Popup>
              <Box sx={{ minWidth: 150 }}>
                <IssueTypeBadge type={issue.type} size="sm" />
                <Box sx={{ mt: 1, display: 'flex', gap: 1, alignItems: 'center' }}>
                  <IssueStateBadge state={issue.state} />
                  <HeatBadge heat={issue.heat} />
                </Box>
                <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                  {new Date(issue.createdAt).toLocaleDateString()}
                </Typography>
              </Box>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </Paper>
  );
};
```

### Step 6: Create IssueMapPage

**File:** `web/src/features/issues/IssueMapPage.tsx`

```typescript
import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';

import { DashboardLayout } from '@/components/templates/DashboardLayout';
import { Breadcrumbs } from '@/components/molecules/Breadcrumbs';
import { ErrorState } from '@/components/molecules/ErrorState';
import { Spinner } from '@/components/atoms/Spinner';
import { IssueTypeFilterBar } from '@/components/molecules/IssueTypeFilterBar';
import { IssueMapCard } from './components/IssueMapCard';
import { useIssuesForMap } from './hooks';
import type { IssueType } from './types';

const ALL_ISSUE_TYPES: IssueType[] = [
  'pothole',
  'water_leak',
  'sewage_leak',
  'traffic_light',
  'street_light',
  'illegal_dumping',
  'other',
];

export const IssueMapPage: FC = () => {
  const { t } = useTranslation();
  const { data: issues, isLoading, error, refetch } = useIssuesForMap();

  const [activeTypes, setActiveTypes] = useState<Set<IssueType>>(
    () => new Set(ALL_ISSUE_TYPES)
  );

  const handleToggle = useCallback((type: IssueType) => {
    setActiveTypes((prev) => {
      const next = new Set(prev);
      if (next.has(type)) {
        next.delete(type);
      } else {
        next.add(type);
      }
      return next;
    });
  }, []);

  const filteredIssues = useMemo(
    () => issues?.filter((issue) => activeTypes.has(issue.type)) ?? [],
    [issues, activeTypes]
  );

  return (
    <DashboardLayout>
      <Breadcrumbs
        title={t('issues.map.title')}
        items={[
          { label: t('dashboard.title'), path: '/', icon: 'home' },
          { label: t('issues.title'), path: '/issues' },
          { label: t('issues.map.title') },
        ]}
      />

      <Box sx={{ mt: 3, display: 'flex', gap: 2, height: 'calc(100vh - 220px)' }}>
        {isLoading && (
          <Box sx={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Spinner />
          </Box>
        )}

        {error && (
          <ErrorState
            title={t('common.error')}
            description={t('errors.serverError')}
            onRetry={() => refetch()}
          />
        )}

        {!isLoading && !error && (
          <>
            <IssueMapCard issues={filteredIssues} />
            <IssueTypeFilterBar activeTypes={activeTypes} onToggle={handleToggle} />
          </>
        )}
      </Box>
    </DashboardLayout>
  );
};

export default IssueMapPage;
```

### Step 7: Add Route

**File:** `web/src/App.tsx`

Add import:

```typescript
import { IssueMapPage } from '@/features/issues/IssueMapPage';
```

Add route BEFORE `/issues/:id`:

```typescript
<Route path="/issues/map" element={<IssueMapPage />} />
<Route path="/issues/:id" element={<IssueDetailPage />} />
```

### Step 8: Add Map Button to IssuesPage

**File:** `web/src/features/issues/IssuesPage.tsx`

Add import:

```typescript
import MapIcon from '@mui/icons-material/Map';
import { ActionButton } from '@/components/atoms/ActionButton';
```

Add `actionSlot` to DataTableCard:

```typescript
<DataTableCard
  // ... existing props
  actionSlot={
    <ActionButton
      icon={<MapIcon />}
      onClick={() => navigate('/issues/map')}
    >
      {t('issues.actions.viewMap')}
    </ActionButton>
  }
/>
```

### Step 9: Add i18n Keys

**File:** `web/src/locales/en/translation.json`

Add under `issues`:

```json
{
  "issues": {
    "actions": {
      "viewMap": "Map"
    },
    "map": {
      "title": "Issue Map",
      "filterByType": "Filter"
    }
  }
}
```

---

## Tests Required

### Unit Tests

**File:** `web/src/components/atoms/IssueTypeFilterButton.test.tsx`

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import { IssueTypeFilterButton } from './IssueTypeFilterButton';

// Mock i18next
vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}));

describe('IssueTypeFilterButton', () => {
  it('renders with active state styling', () => {
    render(
      <IssueTypeFilterButton type="pothole" isActive={true} onClick={vi.fn()} />
    );
    const button = screen.getByRole('button');
    expect(button).toBeInTheDocument();
  });

  it('renders with inactive state styling', () => {
    render(
      <IssueTypeFilterButton type="pothole" isActive={false} onClick={vi.fn()} />
    );
    const button = screen.getByRole('button');
    expect(button).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const onClick = vi.fn();
    render(
      <IssueTypeFilterButton type="pothole" isActive={false} onClick={onClick} />
    );
    await fireEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
```

**File:** `web/src/components/molecules/IssueTypeFilterBar.test.tsx`

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import { IssueTypeFilterBar } from './IssueTypeFilterBar';

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}));

describe('IssueTypeFilterBar', () => {
  it('renders all issue type buttons', () => {
    const activeTypes = new Set(['pothole', 'water_leak'] as const);
    render(
      <IssueTypeFilterBar activeTypes={activeTypes} onToggle={vi.fn()} />
    );
    expect(screen.getAllByRole('button')).toHaveLength(7);
  });

  it('calls onToggle with correct type', async () => {
    const onToggle = vi.fn();
    render(
      <IssueTypeFilterBar activeTypes={new Set()} onToggle={onToggle} />
    );
    const buttons = screen.getAllByRole('button');
    await fireEvent.click(buttons[0]);
    expect(onToggle).toHaveBeenCalledWith('pothole');
  });
});
```

---

## Definition of Done

- [ ] Map button visible in Issues list toolbar (right side)
- [ ] Clicking Map navigates to `/issues/map`
- [ ] Breadcrumb shows: Dashboard > Issues > Issue Map
- [ ] All active issues displayed as colored pins
- [ ] Pins match issue type colors
- [ ] Filter buttons toggle pin visibility
- [ ] Active button: solid color bg, white icon
- [ ] Inactive button: light bg, colored icon
- [ ] Map supports pan and zoom
- [ ] Popup shows issue type, state, heat on pin click
- [ ] All tests passing
- [ ] No lint/typecheck errors
- [ ] Follows web/CLAUDE.md patterns
