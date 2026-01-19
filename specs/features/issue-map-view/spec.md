# Feature: Issue Map View

## Overview

Add a map view for the Issues list that displays all active issues on an interactive map with filtering by issue type.

## User Stories

- **W8**: As an admin, I can view all issues on a map to understand geographic distribution
- **W9**: As an admin, I can filter map pins by issue type to focus on specific problems

## Requirements Summary

| Requirement | Description |
|-------------|-------------|
| Map Button | Add map icon button to Issues list toolbar (right side) |
| Navigation | Map screen as breadcrumb child of Issues list |
| Header | Standard view header titled "Issue Map" |
| Map Display | Full-area map in card frame with thin, light border |
| Pins | Display all active issues as colored pins by type |
| Interaction | Pan and zoom support |
| Filters | Vertical issue type filter buttons on right side |
| Toggle States | On: solid bg + white icon; Off: light bg + colored icon |

## Platform Impact

**Web Only** - This feature is specific to the admin portal.

---

## Implementation Plan

### 1. Theme: Add Issue Type Colors

**File:** `web/src/theme/colors.ts`

Add color definitions for each issue type:

```typescript
export const issueTypeColors = {
  pothole: '#795548',       // Brown
  water_leak: '#2196F3',    // Blue
  sewage_leak: '#4CAF50',   // Green (different from water)
  traffic_light: '#F44336', // Red
  street_light: '#FFC107',  // Amber
  illegal_dumping: '#9C27B0', // Purple
  other: '#9E9E9E',         // Gray
} as const;
```

### 2. Route: Add Map Page Route

**File:** `web/src/App.tsx`

Add route for issue map page:

```typescript
<Route path="/issues/map" element={<IssueMapPage />} />
```

**Note:** Place before `/issues/:id` to avoid route conflict.

### 3. Issues Page: Add Map Button

**File:** `web/src/features/issues/IssuesPage.tsx`

Add `actionSlot` to DataTableCard with Map button:

```typescript
import MapIcon from '@mui/icons-material/Map';

actionSlot={
  <ActionButton
    icon={<MapIcon />}
    onClick={() => navigate('/issues/map')}
  >
    {t('issues.actions.viewMap')}
  </ActionButton>
}
```

### 4. Component: IssueTypeFilterButton (Atom)

**File:** `web/src/components/atoms/IssueTypeFilterButton.tsx`

Toggle button for issue type filtering:

```typescript
interface IssueTypeFilterButtonProps {
  type: IssueType;
  isActive: boolean;
  onClick: () => void;
}
```

**States:**
- **Active (on):** Solid background color, white icon
- **Inactive (off):** Light/toned background, colored icon

Follows hamburger button pattern from ActionButton.

### 5. Component: IssueTypeFilterBar (Molecule)

**File:** `web/src/components/molecules/IssueTypeFilterBar.tsx`

Vertical stack of filter buttons:

```typescript
interface IssueTypeFilterBarProps {
  activeTypes: Set<IssueType>;
  onToggle: (type: IssueType) => void;
}
```

- Displays all issue types as round icon buttons
- Vertical layout (Stack direction="column")
- Manages toggle state per type

### 6. Component: IssueMapCard (Organism)

**File:** `web/src/features/issues/components/IssueMapCard.tsx`

Map display with issue pins:

```typescript
interface IssueMapCardProps {
  issues: IssueSummary[];
  visibleTypes: Set<IssueType>;
}
```

Features:
- Card wrapper with thin border (`border: 1, borderColor: 'divider'`)
- Full height map using react-leaflet
- Custom colored markers per issue type
- Popup on marker click (issue type, state, heat)
- Auto-fit bounds to visible pins

### 7. Page: IssueMapPage

**File:** `web/src/features/issues/IssueMapPage.tsx`

Main page component:

```typescript
export const IssueMapPage: FC = () => {
  const [visibleTypes, setVisibleTypes] = useState<Set<IssueType>>(
    new Set(ALL_ISSUE_TYPES)
  );

  // Fetch all active issues (no pagination for map view)
  const { data, isLoading } = useIssuesForMap();

  const filteredIssues = useMemo(() =>
    data?.filter(issue => visibleTypes.has(issue.type)) ?? [],
    [data, visibleTypes]
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
      <Box sx={{ display: 'flex', gap: 2, mt: 3, height: 'calc(100vh - 200px)' }}>
        <IssueMapCard issues={filteredIssues} flex={1} />
        <IssueTypeFilterBar
          activeTypes={visibleTypes}
          onToggle={handleToggle}
        />
      </Box>
    </DashboardLayout>
  );
};
```

### 8. Hook: useIssuesForMap

**File:** `web/src/features/issues/hooks.ts`

Add query for map view (fetch all active issues):

```typescript
export function useIssuesForMap() {
  return useQuery({
    queryKey: ['issues', 'map'],
    queryFn: () => issueApi.getAllForMap(),
  });
}
```

### 9. API: Add Map Endpoint Function

**File:** `web/src/features/issues/api.ts`

```typescript
getAllForMap: () =>
  apiClient.get<IssueSummary[]>('/v1/issues', {
    params: { limit: 1000 } // All active issues
  }).then(r => r.data.items),
```

### 10. i18n: Add Translation Keys

**File:** `web/src/locales/en/translation.json`

```json
{
  "issues": {
    "actions": {
      "viewMap": "Map"
    },
    "map": {
      "title": "Issue Map",
      "noIssues": "No issues to display",
      "filterByType": "Filter by type"
    }
  }
}
```

---

## File Summary

| File | Action | Description |
|------|--------|-------------|
| `theme/colors.ts` | Modify | Add `issueTypeColors` constant |
| `App.tsx` | Modify | Add `/issues/map` route |
| `features/issues/IssuesPage.tsx` | Modify | Add Map button to actionSlot |
| `components/atoms/IssueTypeFilterButton.tsx` | Create | Toggle button component |
| `components/molecules/IssueTypeFilterBar.tsx` | Create | Vertical filter bar |
| `features/issues/components/IssueMapCard.tsx` | Create | Map with pins organism |
| `features/issues/IssueMapPage.tsx` | Create | Map page |
| `features/issues/hooks.ts` | Modify | Add `useIssuesForMap` hook |
| `features/issues/api.ts` | Modify | Add map endpoint function |
| `locales/en/translation.json` | Modify | Add i18n keys |

---

## Dependencies

- `react-leaflet` (already installed)
- `leaflet` (already installed)
- Existing issue API endpoints (no backend changes needed)

---

## Implementation Order

1. **Theme** - Add issue type colors
2. **Atoms** - IssueTypeFilterButton
3. **Molecules** - IssueTypeFilterBar
4. **API/Hooks** - useIssuesForMap
5. **Organism** - IssueMapCard
6. **Page** - IssueMapPage
7. **Routing** - Add route to App.tsx
8. **Integration** - Add Map button to IssuesPage
9. **i18n** - Add translation keys
10. **Tests** - Component and integration tests

---

## Tests Required

### Unit Tests
- [ ] IssueTypeFilterButton renders active/inactive states
- [ ] IssueTypeFilterButton calls onClick on click
- [ ] IssueTypeFilterBar renders all issue types
- [ ] IssueTypeFilterBar toggles correct type

### Integration Tests
- [ ] IssueMapPage loads issues on mount
- [ ] Filter toggles hide/show pins
- [ ] Map button navigates to map page
- [ ] Breadcrumb navigation works

---

## Definition of Done

- [ ] Map button visible in Issues list toolbar
- [ ] Clicking Map navigates to /issues/map
- [ ] Breadcrumb shows Issues > Issue Map
- [ ] All active issues displayed as pins
- [ ] Pins colored by issue type
- [ ] Filter buttons toggle pin visibility
- [ ] Button states match spec (solid/light backgrounds)
- [ ] Map supports pan and zoom
- [ ] All tests passing
- [ ] No lint/typecheck errors
