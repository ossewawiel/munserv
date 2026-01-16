# MunServ Web Admin Portal

React + TypeScript + MUI admin portal for managing municipal issues.

## Setup

### Prerequisites

- Node.js 20+
- pnpm

### Installation

```bash
cd web
pnpm install
```

### Running the App

1. **Start the backend:**
   ```bash
   cd ../backend
   ./gradlew bootRun
   # Backend runs on http://localhost:8080
   ```

2. **Start the web app:**
   ```bash
   pnpm dev
   # Web app runs on http://localhost:3000
   ```

3. **Login:**
   - Email: `admin@ward42.example.com`
   - Password: `admin123`

## Commands

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start dev server (port 3000) |
| `pnpm build` | Production build |
| `pnpm lint` | ESLint check |
| `pnpm typecheck` | TypeScript check |
| `pnpm test` | Run tests (watch mode) |
| `pnpm test:run` | Run tests (single run) |
| `pnpm test:coverage` | Run tests with coverage |

## Tech Stack

- **React 18** with TypeScript
- **MUI v7** for components and theming
- **React Query** for server state
- **React Router** for navigation
- **Axios** for HTTP client
- **Vitest** for testing
- **Playwright** for E2E testing

## Project Structure

```
src/
├── main.tsx
├── App.tsx
├── theme/                # MUI theme configuration
├── components/
│   ├── atoms/           # Thin wrappers around MUI
│   ├── molecules/       # Combined atoms
│   ├── organisms/       # Complex sections
│   └── templates/       # Page layouts
├── features/
│   ├── issues/          # Issue management
│   ├── members/         # Member management
│   └── dashboard/       # Dashboard stats
├── shared/
│   ├── hooks/
│   ├── utils/
│   └── types/
└── lib/
    ├── api-client.ts
    └── query-client.ts
```

## Development with Claude Code

### Available Skills

| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | Full TDD workflow: Specify → Test → Code → Refactor → Quality |
| `/component` | Generate MUI component (atom/molecule/organism/page) |
| `/page` | Generate page with routing |
| `/hook` | Create React Query hook |
| `/api` | Add API endpoint function |
| `/form` | Create form with React Hook Form + Zod |
| `/i18n` | Add translation keys |
| `/test` | Generate Vitest test |
| `/e2e` | Generate Playwright E2E test |
| `/review` | Code review for patterns |
| `/sonar` | SonarQube analysis |
| `/ci-fix` | Debug CI/CD failures |

### TDD Workflow

```
1. SPECIFY    → Define acceptance criteria
2. TEST       → Write failing tests first (Red)
3. CODE       → Implement to pass tests (Green)
4. REFACTOR   → Clean up, fix review issues
5. QUALITY    → Run lint, typecheck, tests
6. DOCUMENT   → Add i18n keys, JSDoc
```

Use `/dev-cycle "your task"` to orchestrate this workflow.

## Architecture

```
Pages → Organisms → Molecules → Atoms
         ↓
      Hooks (React Query) → API
```

| Layer | Responsibility | Data Fetching |
|-------|----------------|---------------|
| Pages | Route entry, compose organisms | Yes (via hooks) |
| Organisms | Complex UI sections | Sometimes |
| Molecules | Combined atoms | No |
| Atoms | Single UI elements (MUI wrappers) | No |

## Key Patterns

### React Query Hooks
```typescript
export function useIssues(sectorId: string) {
  return useQuery({
    queryKey: ['issues', sectorId],
    queryFn: () => issueApi.getBySector(sectorId),
  });
}
```

### MUI Styling (sx prop)
```typescript
<Box sx={{ p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
<Button variant="contained" color="primary">
<Typography variant="body2" color="text.secondary">
```

### Type Definitions
```typescript
interface Issue {
  id: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  heat: number;
}

type IssueState = 'reported' | 'confirmed' | 'in_progress' | 'fixed' | 'rejected';
```

## Testing

### Unit/Component Tests (Vitest)
```bash
pnpm test              # Watch mode
pnpm test:run          # Single run
pnpm test:coverage     # With coverage
```

### E2E Tests (Playwright)
```bash
npx playwright test           # Run all
npx playwright test --ui      # Interactive UI
npx playwright show-report    # View report
```

## Styling Rules

**DO:** Use MUI's sx prop
```typescript
<Box sx={{ p: 2, bgcolor: 'primary.main', borderRadius: 1 }}>
```

**DON'T:** Use inline styles or CSS classes
```typescript
// BAD - inline styles
<div style={{ padding: '16px' }}>

// BAD - Tailwind/CSS classes
<div className="p-4 bg-white">
```

## Documentation

- [CLAUDE.md](CLAUDE.md) — Architecture patterns, styling rules, coding conventions
- [Web Theming Guide](../specs/Web_Theming_Guide.md) — MUI v7 theming, colors
- [Testing Strategy](../specs/Testing_Strategy.md) — Test patterns
