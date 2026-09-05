# Web card - React 19 + TypeScript 6 + MUI 9 + React Query 5

Read `domain/README.md` first. Load the `web-patterns` skill for worked examples, `web-data-table` for admin lists. Theming: `specs/Web_Theming_Guide.md`.

## Layers
`Pages` → `Organisms` → `Molecules` → `Atoms`, with data through `Hooks (React Query)` → `features/<name>/api.ts`. Pages and organisms may fetch; molecules and atoms never do. Folder: `src/components/{atoms,molecules,organisms,templates}`, `src/features/<name>/{api,hooks,types,components}`, `src/shared/{hooks,types,utils}`, `src/theme`, `src/lib/{api-client,query-client}`.

## The rules that get broken
1. **Server state is React Query.** `useQuery` / `useMutation` in `features/<name>/hooks.ts` with typed query keys; never `useEffect` + `useState` for fetching. Optimistic updates roll back in `onError`.
2. **Styling is the `sx` prop** with theme tokens (`'primary.main'`, `'text.secondary'`, spacing numbers). No CSS classes, no Tailwind, no inline `style`, no literal colours.
3. **MUI 9 API**: `slotProps.input` / `slotProps.paper` / `slotProps.transition` replace the old `*Props`; `sx` replaces system props (`mt={2}`); `Grid` takes `size={{ xs: 12, md: 4 }}`; class assertions in tests use compound selectors (`MuiButton-contained` + `MuiButton-colorPrimary`).
4. **Every user-visible string is an i18n key**: `t('issues.states.reported')`, key shape `{feature}.{context}.{key}`, files in `src/locales/{en,af,zu}/`.
5. **Atomic design**: atoms wrap MUI (`Button`, `Input`, `Badge`, `Spinner`); a new atom needs a story once Storybook lands. Admin lists use `DataTableCard`, never a hand-rolled table.
6. **Types**: `interface` for shapes, `type` for unions; explicit return types on exports; enums as `as const` arrays plus a union; `unknown` with a guard instead of `any`. Wire values are snake_case strings matching `domain/language.yaml`.

## Tests
Vitest 5 + Testing Library + MSW 2 + jest-dom 7 (`@testing-library/jest-dom/vitest`), jsdom 30. Co-located `*.test.tsx`. Query priority: `getByRole` > `getByLabelText` > `getByText` > `getByTestId`. Playwright for E2E in `e2e/`. `pnpm test:visual` (`pnpm test:visual:update` to refresh) screenshots every Storybook story in light and dark against `e2e/visual/__screenshots__/`.

## Commands
```bash
pnpm lint          # ESLint 10 with react-hooks 7 (compiler rules on)
pnpm typecheck     # tsc -b (project references; this is what the build runs)
pnpm test:run      # 653 tests
pnpm build         # tsc -b && vite build
pnpm dev           # port 3000, proxies /api to 8080
```
TypeScript is pinned to 6.0.x until typescript-eslint supports 7.

## Forbidden
`any`; class components; `useEffect` for data; `useState` for server state; prop drilling past two levels; index keys in dynamic lists; business logic in components; CSS classes or Tailwind; `clsx`; literal colours; inline styles; a new enum value that is not also in the backend, mobile and `domain/`.

## Skills
`/dev-cycle`, `/fix-issue`, `/feature`, `/component`, `/page`, `/hook`, `/api`, `/form`, `/i18n`, `/test`, `/e2e`, `/review`, `/ci-fix` in `web/.claude/commands/`.
