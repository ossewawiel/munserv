---
issue: 32
story: W21
title: "Generic data table component: sorting, search and filter panel"
platform: web
status: completed
depends_on: []
touches:
  - web/src/components/organisms
  - web/src/features/pod-chief
  - web/src/locales
  - design/registry
ui: true
design_canvas: "https://claude.ai/code/artifact/0a434154-e4b2-44cc-ad3d-216e11e949e0"
design_artboards:
  - design/canvases/pod-chief-mvp/TableToolbarInert.dc.html
  - design/canvases/pod-chief-mvp/TableSortAscending.dc.html
  - design/canvases/pod-chief-mvp/TableSortDescending.dc.html
  - design/canvases/pod-chief-mvp/TableSearchActive.dc.html
  - design/canvases/pod-chief-mvp/TableFilterPanelDefault.dc.html
  - design/canvases/pod-chief-mvp/TableFilterPanelApplied.dc.html
design_approved: true
created_by: feature-planner
created_at: "2026-09-05"
files_changed:
  - web/src/components/organisms/DataTable.tsx
  - web/src/components/organisms/DataTable.test.tsx
  - web/src/components/organisms/DataTableCard.tsx
  - web/src/components/organisms/DataTableCard.test.tsx
  - web/src/components/organisms/DataTableCard.stories.tsx
  - web/src/features/pod-chief/PodAdministratorsPage.tsx
  - web/src/features/pod-chief/PodAdministratorsPage.test.tsx
  - web/src/locales/en/translation.json
  - web/src/locales/af/translation.json
  - web/src/locales/zu/translation.json
  - design/registry/web.md
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-sort-ascending--light.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-sort-ascending--dark.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-sort-descending--light.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-sort-descending--dark.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-disabled-search-and-filter--light.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-disabled-search-and-filter--dark.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-search-active--light.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-search-active--dark.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-filter-panel-default--light.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-filter-panel-default--dark.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-filter-panel-applied--light.png
  - web/e2e/visual/__screenshots__/stories.spec/organisms-datatablecard--with-filter-panel-applied--dark.png
tests_added:
  - "web/src/components/organisms/DataTable.test.tsx: should render a sort label only for sortable columns"
  - "web/src/components/organisms/DataTable.test.tsx: should disable the sort label when no sort handler is given"
  - "web/src/components/organisms/DataTable.test.tsx: should call onSortChange with the column key when a sortable header is clicked"
  - "web/src/components/organisms/DataTable.test.tsx: should not reorder the rows it is given"
  - "web/src/components/organisms/DataTableCard.test.tsx: should render a disabled search field when no handler is given"
  - "web/src/components/organisms/DataTableCard.test.tsx: should call the search handler as the user types"
  - "web/src/components/organisms/DataTableCard.test.tsx: should render a disabled filter button when no handler is given"
  - "web/src/components/organisms/DataTableCard.test.tsx: should open the filter drawer and show its content"
  - "web/src/components/organisms/DataTableCard.test.tsx: should close the filter drawer"
  - "web/src/components/organisms/DataTableCard.test.tsx: should badge the filter button with the active filter count"
  - "web/src/components/organisms/DataTableCard.test.tsx: should disable the clear button when no clear handler is given"
  - "web/src/components/organisms/DataTableCard.test.tsx: should call onClear when the clear button is enabled and clicked"
  - "web/src/features/pod-chief/PodAdministratorsPage.test.tsx: should show a disabled search field"
  - "web/src/features/pod-chief/PodAdministratorsPage.test.tsx: should show a disabled filter button"
  - "web/src/features/pod-chief/PodAdministratorsPage.test.tsx: should show sortable headers that do nothing"
---

# W21 · Data table sorting, search and filter panel (Web)

Read `domain/README.md` for every term used below, and load the `web-data-table` skill. This handoff
is complete on its own; do not read the feature spec or other stories' handoffs.

**Four of the six acceptance criteria already ship.** `web/src/components/organisms/DataTableCard.tsx`
and `DataTable.tsx` give column definitions (`Column<T>`), an actions column (a `Column` with
`key: 'actions'`, as `PodAdministratorsPage` uses), an add-button slot (`actionSlot`) and a free-form
`filterSlot` that a search field can sit in. What does **not** exist anywhere in `web/src` is column
sorting and a filter slide-out panel: `grep -rn "TableSortLabel\|sortable" web/src` returns nothing,
and the only `Drawer` in the codebase is the navigation one in `components/templates`. Build those
two, and make the search field a first-class prop so every table gets the same one.

## Acceptance criteria
- [ ] Supports column definitions
- [ ] Sort by columns (prepared, can be disabled)
- [ ] Search input (prepared, can be disabled)
- [ ] Filter slide-out panel (prepared, can be disabled)
- [ ] Actions column
- [ ] Add button slot

"Prepared, can be disabled" means: the control renders, is visibly inert, and becomes live the
moment the caller passes a handler. For the MVP every caller passes no handler.

## Visual (ui stories only)
Match artboards: to be produced by the designer under `design/canvases/pod-chief-mvp/` — the toolbar
with the search field and filter button (enabled and disabled), a sortable header in each direction,
and the open filter drawer. The artboards outrank the words here.
`DataTableCard` already has a `design/registry/web.md` row; update that row's Notes to name the new
props rather than adding a row, and extend `DataTableCard.stories.tsx` (step 5) so the visual gate
renders every new state.

## Contract
None. This is a presentational component; it calls no API and adds no type to `specs/contracts/`.

## Steps

1. `web/src/components/organisms/DataTable.tsx`: add `readonly sortable?: boolean` to `Column<T>`
   and `readonly sort?: SortState`, `readonly onSortChange?: (key: string) => void` to
   `DataTableProps<T>`, with
   `export interface SortState { readonly key: string; readonly direction: 'asc' | 'desc' }`.
   A header cell with `sortable` renders an MUI `TableSortLabel` with
   `active={sort?.key === column.key}`, `direction={sort?.key === column.key ? sort.direction : 'asc'}`,
   `disabled={!onSortChange}` and `onClick={() => onSortChange?.(column.key)}`; every other header
   renders exactly as it does today. Do not sort `data` here — sorting is the caller's, usually the
   server's. Test: `web/src/components/organisms/DataTable.test.tsx` (new) —
   `should render a sort label only for sortable columns`,
   `should disable the sort label when no sort handler is given`,
   `should call onSortChange with the column key when a sortable header is clicked`,
   `should not reorder the rows it is given`.
2. `web/src/components/organisms/DataTableCard.tsx`: add three optional props and pass sorting
   straight through to `DataTable`:
   ```ts
   readonly sort?: SortState | null;
   readonly onSortChange?: (key: string) => void;
   readonly search?: { readonly value: string; readonly placeholder?: string;
                       readonly onChange?: (value: string) => void };
   readonly filterPanel?: { readonly content: ReactNode; readonly activeCount?: number;
                            readonly onClear?: () => void };
   ```
   When `search` is set, render the `Input` atom at the head of the toolbar's left box with
   `size="small"`, a `SearchIcon` through `slotProps.input.startAdornment` (MUI 9: `slotProps`, not
   `InputProps`), and `disabled={!search.onChange}`; `filterSlot` keeps its place after it. When
   `filterPanel` is set, render an `ActionButton` with `icon={<FilterListIcon />}` at the head of the
   toolbar's right box, enabled whenever `filterPanel` is set (only the clear button is gated on
   `filterPanel.onClear`, so the panel and its placeholder copy stay reachable), wrapped in an MUI `Badge` showing
   `activeCount` when it is above zero; clicking it opens an MUI `Drawer` with `anchor="right"`,
   `slotProps={{ paper: { sx: { width: { xs: '100%', sm: 360 } } } }}`, a header with the title and a
   close `IconButton`, `filterPanel.content` as the body, and a clear button calling
   `filterPanel.onClear`. Hold the drawer's open state in `useState`; it is UI state, not server
   state. Test: `DataTableCard.test.tsx` — `should render a disabled search field when no handler is given`,
   `should call the search handler as the user types`,
   `should render a disabled filter button when no handler is given`,
   `should open the filter drawer and show its content`,
   `should close the filter drawer`, `should badge the filter button with the active filter count`,
   and every existing case stays green.
3. `web/src/features/pod-chief/PodAdministratorsPage.tsx`: mark the `displayName`, `email`, `role`,
   `assignedTo` and `createdAt` columns `sortable: true` (never `actions`), and pass
   `search={{ value: '' }}` and `filterPanel={{ content: <Typography>{t('podAdministrators.filters.comingSoon')}</Typography> }}`
   with no handlers, so all three controls render inert. Test:
   `web/src/features/pod-chief/PodAdministratorsPage.test.tsx` (new) —
   `should show a disabled search field`, `should show a disabled filter button`,
   `should show sortable headers that do nothing`.
4. `web/src/locales/{en,af,zu}/translation.json`: add a `dataTable` block (`searchPlaceholder`,
   `filters`, `filtersTitle`, `clearFilters`, `closeFilters`, `sortBy`) and
   `podAdministrators.filters.comingSoon`. Real Afrikaans and isiZulu translations.
5. `web/src/components/organisms/DataTableCard.stories.tsx`: add `WithSortableColumns`,
   `WithDisabledSearchAndFilter` and `WithOpenFilterDrawer` stories, and update the `DataTableCard`
   row in `design/registry/web.md` to mention `sort`, `onSortChange`, `search` and `filterPanel`.

## Do not
- Do not sort, filter or search the `data` array inside the component. It renders what it is given;
  the caller owns the query. A component that reorders rows breaks every server-paginated table.
- Do not add `useEffect`-driven state syncing or a `useState` copy of `data`; both are forbidden by
  `web/CLAUDE.md`.
- Do not use MUI 8 prop names. `slotProps.input`, `slotProps.paper`, `size={{ xs: 12 }}` on `Grid`,
  and `sx` instead of system props.
- Do not remove or rename `filterSlot`, `actionSlot`, `tabs` or any existing prop:
  `IssuesPage`, `MembersPage`, `GroundAdminsPage`, `AdminManagementPage`, `SupportGrantsTable` and
  `PodAdministratorsPage` all depend on them, and their tests must stay green untouched.
- Do not wire real search, sorting or filtering into any page. Every control is inert for the MVP;
  a live one needs its own story and a backend query parameter.
- Do not add a debounce, a `lodash` import or `clsx`.
- Do not touch backend, mobile or `specs/contracts/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end, not after every step
cd web && pnpm lint && pnpm typecheck && pnpm test:run
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with a
summary of changes. If you cannot finish, set `status: blocked` and end your message with
`BLOCKED: <reason>`.

## Eyeball
```yaml
- id: E1
  title: Sortable column headers are inert on the live page, active in the catalogue
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - Log in as the pod chief and open Pod Administrators.
    - Click the "Name", "Email", "Role", "Assigned To" or "Created" column header.
  expect: Each header shows a sort arrow but clicking it does nothing; the row order and data never change.
- id: E2
  title: Search field and Filters button render but do nothing on the live page
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - On Pod Administrators, type into the search field at the head of the toolbar.
    - Click the "Filters" button.
  expect: The search field is disabled and ignores typing; the Filters button opens a drawer titled
    "Filters" showing "Filtering is not switched on yet..." with a disabled Clear filters button.
- id: E3
  title: DataTableCard catalogue demonstrates every new state
  as: none
  services: [storybook]
  url: http://localhost:6006/?path=/story/organisms-datatablecard--with-sort-ascending
  steps:
    - Open the Storybook sidebar under Organisms > DataTableCard.
    - Visit the With Sort Ascending, With Sort Descending, With Disabled Search And Filter,
      With Search Active, With Filter Panel Default and With Filter Panel Applied stories.
  expect: Sort arrows point the right way in each sort story; the search field is visibly enabled
    with a typed value in With Search Active; the Filters button is enabled and its drawer is open
    in both filter panel stories, with a "2" badge and populated Clear button only in Applied.
```
