# MUI Component Generator

name: "component"
description: "Generate MUI component at any atomic level (atom, molecule, organism, template, page)"
parameters:
  - name: "name"
    description: "Component name in PascalCase (e.g., IssueCard, StatWidget)"
    required: true
  - name: "level"
    description: "Atomic level: atom, molecule, organism, template, page"
    required: true
  - name: "feature"
    description: "Feature folder name for organisms/pages (e.g., issues, members)"
    required: false

---

You are an expert React developer generating MUI v7 components for the MunServ web admin portal.

## Task

Generate a {{level}}-level component named `{{name}}` following the project's atomic design patterns and MUI v7 styling conventions.

## Component Location by Level

| Level | Path | Data Fetching |
|-------|------|---------------|
| atom | `src/components/atoms/{{name}}.tsx` | Never |
| molecule | `src/components/molecules/{{name}}.tsx` | Never |
| organism | `src/features/{{feature}}/components/{{name}}.tsx` | Sometimes (via hooks) |
| template | `src/components/templates/{{name}}.tsx` | Never |
| page | `src/features/{{feature}}/{{name}}.tsx` | Yes (via hooks) |

## Required Patterns

### Import Order (STRICT)
```typescript
// 1. React
import { useState, useCallback, useMemo, type FC } from 'react';

// 2. Third-party libraries
import { useQuery } from '@tanstack/react-query';

// 3. MUI components (individual imports)
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

// 4. Project absolute imports (@/ alias)
import { useAuth } from '@/shared/hooks/useAuth';

// 5. Feature-relative imports
import { useIssues } from './hooks';
import type { Issue } from './types';
```

### Props Interface Pattern
```typescript
interface {{name}}Props {
  // Required props first
  data: DataType;
  // Optional props with defaults
  variant?: 'primary' | 'secondary';
  onAction?: (item: DataType) => void;
}
```

### Component Pattern
```typescript
export const {{name}}: FC<{{name}}Props> = ({
  data,
  variant = 'primary',
  onAction,
}) => {
  // Hooks at top
  const [isOpen, setIsOpen] = useState(false);

  // Memoized values
  const processedData = useMemo(() => /* ... */, [data]);

  // Handlers with useCallback
  const handleClick = useCallback(() => {
    onAction?.(data);
  }, [onAction, data]);

  return (
    <Box sx={{ /* MUI sx prop styling */ }}>
      {/* Component content */}
    </Box>
  );
};
```

## MUI sx Prop Rules (CRITICAL)

### DO: Use Theme Tokens
```typescript
<Box sx={{
  p: 2,                          // spacing (2 = 16px)
  bgcolor: 'background.paper',   // theme color
  color: 'text.primary',         // theme color
  borderRadius: 2,               // theme.shape.borderRadius * 2
  border: 1,                     // 1px
  borderColor: 'divider',        // theme color
  '&:hover': {
    bgcolor: 'action.hover',
  },
}}>
```

### DO: Use Responsive Values
```typescript
<Box sx={{
  p: { xs: 1, sm: 2, md: 3 },
  display: { xs: 'none', md: 'flex' },
}}>
```

### DON'T: Hardcode Colors or Use CSS Classes
```typescript
// BAD - hardcoded color
<Box sx={{ bgcolor: '#ffffff' }}>

// BAD - inline style
<div style={{ padding: '16px' }}>

// BAD - CSS class
<div className="p-4 bg-white">
```

## Level-Specific Rules

### Atom
- Single MUI component wrapper
- Props extend MUI component props
- No business logic
- Export from `src/components/atoms/index.ts`

### Molecule
- 2-3 atoms combined
- No data fetching
- Simple local state only
- Pure presentation

### Organism
- Multiple molecules
- Can use React Query hooks
- Contains presentation logic
- Feature-scoped
- For tabbed data tables, use `DataTableCard` with `tabs` prop (see CLAUDE.md)

### Template
- Layout structure only
- Slots for content (children)
- No data fetching
- Reusable across features

### Page
- Route entry point
- Uses React Query hooks for data
- Composes organisms
- Handles routing logic

## Output

Generate the complete component file with:
1. Proper imports (following import order)
2. TypeScript interface for props
3. Functional component with hooks
4. MUI sx prop styling (theme tokens only)
5. Proper exports

Then update the barrel export if needed:
- Atoms/Molecules: Add to `src/components/{level}/index.ts`
- Organisms: Add to feature's `components/index.ts` if exists
