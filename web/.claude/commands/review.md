# Code Review for Web Patterns

name: "review"
description: "Review code for adherence to web patterns and identify issues"
parameters:
  - name: "target"
    description: "File or directory path to review (e.g., src/features/issues/)"
    required: true
  - name: "focus"
    description: "Focus area: all, styling, hooks, types, performance"
    required: false
    default: "all"

---

You are an expert React developer reviewing code for the MunServ web admin portal.

## Task

Review `{{target}}` for adherence to project patterns and best practices.

## Review Criteria by Severity

### CRITICAL (Must Fix Before Merge)

#### TypeScript
- [ ] Using `any` type
- [ ] Missing type annotations on exported functions
- [ ] Non-null assertion (`!`) without prior check
- [ ] Type casting without validation

#### React
- [ ] Using class components
- [ ] useEffect for data fetching (should use React Query)
- [ ] useState for server state (should use React Query)
- [ ] Missing key prop in lists
- [ ] Index as key in dynamic lists

#### Styling
- [ ] Inline styles (`style={{}}`)
- [ ] CSS class names (`className="..."`)
- [ ] Tailwind classes
- [ ] Hardcoded colors (e.g., `#ffffff`, `rgb()`)
- [ ] Using `clsx` or `classnames`

#### Security
- [ ] Storing sensitive data in localStorage
- [ ] Exposing API keys or secrets
- [ ] Unsafe innerHTML usage

### HIGH (Should Fix)

#### TypeScript
- [ ] Using `object` or `{}` type
- [ ] Missing return types on hooks
- [ ] Inconsistent interface vs type usage
- [ ] Missing readonly modifiers

#### React
- [ ] Missing useCallback for handlers passed to children
- [ ] Missing useMemo for expensive computations
- [ ] Prop drilling beyond 2 levels
- [ ] Business logic in components
- [ ] Missing error boundaries

#### Hooks
- [ ] Dependencies array issues in useEffect/useCallback/useMemo
- [ ] Conditional hook calls
- [ ] Missing cleanup in useEffect

#### Performance
- [ ] Inline function/object creation in render
- [ ] Large component files (>200 lines)
- [ ] Missing React.memo for pure components

### MEDIUM (Consider Fixing)

#### Code Organization
- [ ] Wrong import order (React → third-party → MUI → project → relative)
- [ ] Missing barrel exports
- [ ] Inconsistent file naming

#### React Query
- [ ] Missing staleTime configuration
- [ ] Missing enabled flag for conditional queries
- [ ] Suboptimal query key structure

#### Styling
- [ ] Magic numbers in spacing (use theme.spacing)
- [ ] Missing responsive breakpoints
- [ ] Inconsistent spacing patterns

### LOW (Nice to Have)

- [ ] Missing JSDoc comments on complex functions
- [ ] Suboptimal destructuring
- [ ] Verbose conditionals that could be simplified
- [ ] Missing test coverage

## Best Practices Checklist

### Vite Best Practices
```typescript
// GOOD - ES module imports
import { something } from 'package';
import Component from './Component';

// BAD - CommonJS
const something = require('package'); // ❌
```

```typescript
// GOOD - Environment variables
const apiUrl = import.meta.env.VITE_API_URL;

// BAD - process.env
const apiUrl = process.env.REACT_APP_API_URL; // ❌
```

### TypeScript Best Practices
```typescript
// GOOD - Explicit types
interface UserProps {
  user: User;
  onUpdate: (user: User) => void;
}

export const UserCard: FC<UserProps> = ({ user, onUpdate }) => {
  // ...
};

// BAD - any type
const data: any = response; // ❌
const handler = (e: any) => {}; // ❌
```

### React Best Practices
```typescript
// GOOD - React Query for server state
const { data, isLoading } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
});

// BAD - useEffect for data fetching
useEffect(() => {
  fetch('/api/users').then(setUsers); // ❌
}, []);
```

```typescript
// GOOD - useCallback for handlers
const handleClick = useCallback(() => {
  onSelect(item);
}, [onSelect, item]);

// BAD - Inline function in JSX (in loops)
{items.map(item => (
  <Button onClick={() => onSelect(item)} /> // ❌ in loops
))}
```

### MUI Styling Best Practices
```typescript
// GOOD - Theme tokens
<Box sx={{
  p: 2,
  bgcolor: 'background.paper',
  color: 'text.primary',
  borderColor: 'divider',
}}>

// BAD - Hardcoded values
<Box sx={{
  padding: '16px',         // ❌ use p: 2
  backgroundColor: '#fff', // ❌ use bgcolor: 'background.paper'
  color: '#333',           // ❌ use color: 'text.primary'
}}>
```

## Output Format

For each issue found, add a TODO comment in this format:

```typescript
// TODO: [SEVERITY] Issue description - Fix: specific solution
```

Example:
```typescript
// TODO: CRITICAL Using any type - Fix: Define proper interface for data
const processData = (data: any) => { // TODO: HIGH Define interface

// TODO: HIGH Missing useCallback - Fix: Wrap with useCallback([onSelect, item])
const handleClick = () => onSelect(item);

// TODO: MEDIUM Import order incorrect - Fix: Move MUI imports after third-party
import Button from '@mui/material/Button';
import { useQuery } from '@tanstack/react-query';
```

## Summary Report

After review, provide:

1. **Issue Count by Severity**
   - CRITICAL: X issues
   - HIGH: X issues
   - MEDIUM: X issues
   - LOW: X issues

2. **Top Issues to Address**
   - List the most impactful issues

3. **Recommendations**
   - Patterns to adopt project-wide
   - Refactoring suggestions

## Output

1. Read all files in `{{target}}`
2. Check against all criteria for `{{focus}}` area
3. Add TODO comments for issues found
4. Provide summary report
5. Prioritize by severity
