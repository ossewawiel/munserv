---
issue: 149
story: W21b
title: "Live sorting, search and filters on the Pod Administrators page"
platform: web
status: pending
depends_on: [32, 152]
touches:
  - web/src/features/pod-chief
  - web/src/shared/hooks
  - web/src/locales
ui: false
design_canvas: "https://claude.ai/code/artifact/0a434154-e4b2-44cc-ad3d-216e11e949e0"
design_artboards:
  - design/canvases/pod-chief-mvp/TableSortAscending.dc.html
  - design/canvases/pod-chief-mvp/TableSortDescending.dc.html
  - design/canvases/pod-chief-mvp/TableSearchActive.dc.html
  - design/canvases/pod-chief-mvp/TableFilterPanelApplied.dc.html
design_approved: true
created_by: feature-planner
created_at: "2026-09-10"
files_changed: []
tests_added: []
---

# W21b · Live Pod Administrators table (Web)

Read `domain/README.md` and `domain/admin-role.md` for every term used below, and load the
`web-data-table` skill. This handoff is complete on its own; do not read the feature spec or other
stories' handoffs.

`ui: false` **on purpose.** Every state this story ships was already drawn and approved for W21 on
the Pod Administrators page: `TableSearchActive` (search term typed, list narrowed),
`TableFilterPanelApplied` (role checkboxes ticked, "Assigned to" select, badge on the Filters
button, filtered list), `TableSortAscending` and `TableSortDescending`. W21 shipped those controls
inert; this story makes them do what the artboards already show. No new screen, dialog or component
shape — so no new canvas.

## Outcome
A pod chief sorts, searches and filters the Pod Administrators table for real: every control asks
the server, and the result is in the URL so it survives a refresh and can be shared.

## Acceptance criteria
- [ ] Clicking a sortable header sorts the list server-side and shows the direction on that header; clicking again reverses it
- [ ] The search field filters the list by email or name as the user types, debounced by 300ms
- [ ] The filter panel offers role (multi-select) and ward, narrows the list when applied, badges the Filters button with how many filters are active, and clears them
- [ ] Sort, search and filters are in the URL query string and survive a reload and the browser Back button
- [ ] When nothing matches, the table says so in words that mention the search or filters
- [ ] `pnpm lint`, `pnpm typecheck` and `pnpm test:run` pass

## Visual
Match the approved artboards named in the frontmatter; they outrank the words here.
Two deliberate departures, both already agreed in this handoff:
- `TableFilterPanelApplied` draws four of the six roles for space. Render **all** of `ADMIN_ROLES`,
  highest first (`pod_chief`, `pod_admin`, `ward_chief`, `ward_admin`, `sector_chief`,
  `sector_admin`), same checkbox row shape as the artboard.
- The artboards mark `Assigned To` sortable. B12 (#152) sorts four columns only and `assignedTo` is
  a label this page derives from level/ward/sector, so drop `sortable` from that column.
The Filters drawer, its title, divider and full-width "Clear filters" button already come from
`DataTableCard`; this story only supplies the drawer's body.

## Contract
`GET /api/v1/pod/administrators` from `specs/contracts/api.md` § Pod Administrators, shipped by
B12 (#152). Query parameters, all optional:

| Param | Values | Default |
|---|---|---|
| `sort` | `<column>:<direction>`; column is `email`, `displayName`, `role` or `createdAt`, direction is `asc` or `desc` | `createdAt:asc` |
| `q` | case-insensitive substring over email **or** display name | none |
| `role` | `admin_role` wire value, repeatable: `?role=ward_chief&role=sector_admin` | none |
| `wardId` | ward UUID | none |

Response is unchanged from today — `{ items: PodAdministrator[], total: number }`, unpaginated,
`total` counted after filtering. Bad parameters answer
`400 { code: "invalid_sort" | "invalid_role" | "invalid_ward_id", message }`; the page never sends
one, so no new error UI.

## Steps

1. `web/src/shared/hooks/useDebouncedCallback.ts` (new):
   `export function useDebouncedCallback<TArgs extends readonly unknown[]>(callback: (...args: TArgs) => void, delayMs: number): (...args: TArgs) => void`.
   Keep the timer id and the latest callback in refs, clear the pending timer on every call and on
   unmount, and return a `useCallback`-stable function. The only `useEffect` is the unmount cleanup —
   this is UI timing, not data fetching. Test:
   `web/src/shared/hooks/useDebouncedCallback.test.ts` (new, `renderHook` + `vi.useFakeTimers`) —
   `should call the callback once after the delay`, `should restart the delay when called again`,
   `should pass the latest arguments`, `should not call the callback after unmount`.
2. `web/src/features/pod-chief/types.ts`: add
   ```ts
   export type PodAdministratorSortColumn = 'displayName' | 'email' | 'role' | 'createdAt';
   export interface PodAdministratorSort { readonly column: PodAdministratorSortColumn; readonly direction: 'asc' | 'desc' }
   export interface PodAdministratorQuery {
     readonly q?: string;
     readonly roles?: readonly AdminRole[];
     readonly wardId?: string;
     readonly sort?: PodAdministratorSort;
   }
   export const POD_ADMINISTRATOR_SORT_COLUMNS = ['displayName', 'email', 'role', 'createdAt'] as const;
   ```
   No change to `PodAdministrator` or `PodAdministratorListResponse`.
3. `web/src/features/pod-chief/api.ts`: `listAdministrators(query: PodAdministratorQuery = {})`
   builds a `URLSearchParams` — `q` when non-empty, one `append('role', role)` per role,
   `wardId`, and `sort` as `` `${column}:${direction}` `` — and requests
   `/pod/administrators` with `?` + the string only when it is non-empty. Test:
   `web/src/features/pod-chief/api.test.ts` (extend if it exists, otherwise new, mocking
   `@/lib/api-client`) — `should request the plain path when the query is empty`,
   `should serialise sort as column and direction`, `should repeat the role parameter for each role`,
   `should omit a blank search term`.
4. `web/src/features/pod-chief/hooks.ts`: add
   `administratorList: (query: PodAdministratorQuery) => [...podChiefKeys.administrators(), query] as const`
   to `podChiefKeys` and give `usePodAdministrators(query: PodAdministratorQuery = {})` that key and
   `queryFn: () => podChiefApi.listAdministrators(query)`. The mutations keep invalidating
   `podChiefKeys.administrators()`, which is still the prefix of every list key — do not change them.
   Test: `web/src/features/pod-chief/hooks.test.ts` (extend if it exists, otherwise new) —
   `should key the administrator list by its query`.
5. `web/src/features/pod-chief/components/PodAdministratorFilters.tsx` (new): the drawer body.
   Props `{ roles: readonly AdminRole[]; wardId: string | null; wards: readonly { id: string; name: string }[]; onRolesChange: (roles: readonly AdminRole[]) => void; onWardChange: (wardId: string | null) => void }`,
   all `readonly`. Renders a "Role" group label plus one MUI `FormControlLabel` + `Checkbox` per
   `ADMIN_ROLES` (labels from `ADMIN_ROLE_LABELS`, order as in the Visual section), and an
   "Assigned to" `FormControl` + `Select` whose first item is `''` → "All assignments" followed by
   the wards. Ticking or unticking a role calls `onRolesChange` with a new array (never mutate);
   choosing an item calls `onWardChange(value || null)`. No data fetching in this component. Test:
   `web/src/features/pod-chief/components/PodAdministratorFilters.test.tsx` (new) —
   `should render a checkbox for every admin role`, `should check the roles it is given`,
   `should add a role when an unchecked box is clicked`, `should remove a role when a checked box is clicked`,
   `should list every ward under all assignments`, `should report null when all assignments is chosen`.
6. `web/src/features/pod-chief/PodAdministratorsPage.tsx`: the wiring.
   - URL is the state, through `useSearchParams` as `MembersPage` does: `q`, `sort`, `ward`, and
     `role` repeated (`searchParams.getAll('role')`). Parse `sort` as `column:direction`, keeping it
     only when the column is in `POD_ADMINISTRATOR_SORT_COLUMNS` and the direction is `asc`/`desc`;
     anything else is treated as no sort. Every writer copies:
     `setSearchParams((prev) => { const next = new URLSearchParams(prev); ...; return next; })`.
   - Pass the parsed query to `usePodAdministrators`, `sort={parsedSort}` (null when the URL has
     none, so no header shows a direction and the server's `createdAt:asc` default applies) and
     `onSortChange={handleSortChange}`: same column toggles `asc`↔`desc`, a different column starts
     at `asc`, and the result is written to the URL.
   - `search={{ value: searchInput, onChange: handleSearchChange }}` where `searchInput` is
     `useState` seeded from `searchParams.get('q') ?? ''`; `handleSearchChange` sets it immediately
     and hands the value to a `useDebouncedCallback(..., SEARCH_DEBOUNCE_MS)` that writes or deletes
     `q` with `{ replace: true }` so typing does not fill the history.
     `const SEARCH_DEBOUNCE_MS = 300;` at module scope — no bare number.
   - `filterPanel={{ content: <PodAdministratorFilters ... />, activeCount: roles.length + (wardId ? 1 : 0), onClear }}`;
     `wards` comes from `usePodSetup()` exactly as `CreatePodAdminDialog` gets it; `onClear` deletes
     `role` and `ward` from the URL and leaves `q` alone (the drawer holds filters, not the search).
   - Drop `sortable: true` from the `assignedTo` column; keep it on `displayName`, `email`, `role`
     and `createdAt`; never on `actions`.
   - `emptyMessage`: when any of `q`, `role`, `ward` is set, render
     `t('podAdministrators.emptyFiltered')` in the same `Box`/`Typography` as today; otherwise the
     existing `podAdministrators.empty`.
   - Leave `hidePagination`, `currentPage`, `pageSize`, the three dialogs and the add button as they
     are.
   Test: `web/src/features/pod-chief/PodAdministratorsPage.test.tsx` — turn the `./hooks` mock's
   `usePodAdministrators` into a `vi.fn()` so the query it receives can be asserted, render inside
   `MemoryRouter` with `initialEntries`, and replace the three inert cases with
   `should read the sort search and filters from the url` (entry
   `/pod-administrators?q=khumalo&role=ward_chief&role=ward_admin&ward=ward-1&sort=displayName:desc`
   → the hook is called with the matching query),
   `should ignore an unknown sort column in the url`,
   `should toggle the direction when the same header is clicked twice`,
   `should send the search term after the debounce` (`vi.useFakeTimers`, `fireEvent.change`, then
   `act(() => vi.advanceTimersByTime(300))`), `should not send the search term before the debounce`,
   `should badge the filter button with the number of active filters`,
   `should show the filtered empty message when a search matches nothing`.
7. `web/src/locales/{en,af,zu}/translation.json`: add `podAdministrators.filters.role`,
   `podAdministrators.filters.assignedTo`, `podAdministrators.filters.allAssignments` and
   `podAdministrators.emptyFiltered`, and delete `podAdministrators.filters.comingSoon` from all
   three files — the panel is live now and W21's placeholder is dead copy. Real Afrikaans and
   isiZulu translations, not English copies. The search placeholder stays `dataTable.searchPlaceholder`.

## Do not
- Do not sort, search or filter `data` in the browser. `DataTable` renders what it is given and B12
  owns the query; an in-page `.filter()` or `.sort()` fails this story.
- Do not add `page` / `limit` to the request or turn the pagination footer on. B12 returns the whole
  filtered set and the page still passes `hidePagination`.
- Do not send `sort=assignedTo` (or `level`, `sectorId`): B12 answers 400 for anything outside the
  four columns.
- Do not `useEffect` to mirror the URL into state, and do not keep a `useState` copy of the list.
  The URL is the single source of truth for the query; only the raw search text is local state.
- Do not touch `DataTableCard.tsx`, `DataTable.tsx`, their stories or the visual screenshots — the
  `sort`, `search` and `filterPanel` API from W21 (#32) is exactly what this story consumes.
- Do not fetch wards from a new endpoint. `usePodSetup()` is the same source
  `CreatePodAdminDialog` already uses.
- Do not add `lodash`, a debounce package or `clsx`; do not touch backend or mobile.

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
  title: Sorting a column reorders the list and shows in the URL
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - 'Log in at http://localhost:3000/login as podchief@munserv.local / podchief123 and open http://localhost:3000/pod-administrators.'
    - 'Click the Name header, then click it a second time.'
    - 'Reload the page with the browser reload button.'
  expect: The first click sorts the names A to Z with an up arrow on Name and the address bar shows ?sort=displayName:asc; the second click reverses the rows and the arrow, with ?sort=displayName:desc; after the reload the same order and arrow are still there.
- id: E2
  title: Search narrows the list as you type
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - 'On http://localhost:3000/pod-administrators, type ward into the search field and wait a moment.'
    - 'Clear the field, then type zzzz.'
    - 'Press the browser Back button.'
  expect: Typing ward leaves only the ward administrators, roughly a third of a second after the last keystroke, and the address bar gains ?q=ward; zzzz leaves an empty table with a message about no matches for the search or filters, not "no administrators yet"; Back restores the previous result.
- id: E3
  title: Role and ward filters apply, badge and clear
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators
  steps:
    - 'On http://localhost:3000/pod-administrators, click Filters, tick Ward Chief and Ward Admin, and close the drawer with the X.'
    - 'Open Filters again and choose Test Ward North under "Assigned to".'
    - 'Open Filters again and click Clear filters.'
  expect: The table shows only the two ward administrators and the Filters button carries a badge of 2 with ?role=ward_chief&role=ward_admin in the address bar; picking the ward makes the badge 3 and keeps only administrators of that ward; Clear filters empties the drawer's selections, removes the badge and the role/ward parameters, and brings every administrator back.
- id: E4
  title: A shared link reproduces the same table
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/pod-administrators?q=ward&role=ward_admin&sort=email:desc
  steps:
    - 'Paste http://localhost:3000/pod-administrators?q=ward&role=ward_admin&sort=email:desc into the address bar and press Enter.'
  expect: The page opens with ward in the search field, a badge of 1 on Filters, Ward Admin ticked inside the drawer, the Email header showing a descending arrow, and only the matching administrators listed.
```
