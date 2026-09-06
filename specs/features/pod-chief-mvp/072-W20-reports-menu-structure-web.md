---
issue: 31
story: W20
title: "Reports menu structure"
platform: web
status: completed
depends_on: []
touches:
  - web/src/features/reports
  - web/src/App.tsx
  - web/src/locales
ui: true
design_canvas: "https://claude.ai/code/artifact/0a434154-e4b2-44cc-ad3d-216e11e949e0"
design_artboards:
  - design/canvases/pod-chief-mvp/ReportsMenuGeneral.dc.html
  - design/canvases/pod-chief-mvp/ReportsWardScope.dc.html
design_approved: true
created_by: feature-planner
created_at: "2026-09-05"
files_changed:
  - web/src/features/reports/types.ts
  - web/src/features/reports/ReportsPage.tsx
  - web/src/features/reports/ReportsPage.test.tsx
  - web/src/App.tsx
  - web/src/components/templates/Sidebar.test.tsx
  - web/src/locales/en/translation.json
  - web/src/locales/af/translation.json
  - web/src/locales/zu/translation.json
tests_added:
  - web/src/features/reports/ReportsPage.test.tsx: should render the three report tabs
  - web/src/features/reports/ReportsPage.test.tsx: should show the ward name in the breadcrumb for a ward report
  - web/src/features/reports/ReportsPage.test.tsx: should put the selected tab in the query string
  - web/src/features/reports/ReportsPage.test.tsx: should fall back to the summary tab for an unknown tab value
  - web/src/components/templates/Sidebar.test.tsx: should list General plus one reports entry per ward under Reports for a pod chief
---

# W20 · Reports menu structure (Web)

Read `domain/README.md`, `domain/ward.md` and `domain/sector.md` for every term used below. This
handoff is complete on its own; do not read the feature spec or other stories' handoffs.

## Outcome
A pod chief clicking any entry under Reports lands on a real reports page with its scope in the
breadcrumb and its tab strip in place, ready for content, instead of a bare "coming soon" line.

## Acceptance criteria
- [ ] Pod reports submenu entry
- [ ] Ward/sector submenu entries
- [ ] Clicking goes to placeholder page with tabbed structure

AC1 and AC2 already ship in `web/src/components/templates/Sidebar.tsx`: `podChiefNavItems` has a
collapsible `nav.reports` item whose children are `nav.generalReports` plus one entry per ward and
per sector from `usePodSetup()`. Change none of it; step 4 pins it with a test. AC3 is the work:
`App.tsx` currently routes `/reports/general`, `/reports/ward/:wardId` and `/reports/sector/:sectorId`
to the file-local `PlaceholderPage`, which has no tabs, no breadcrumb and no scope.

## Visual (ui stories only)
Match artboard: to be produced by the designer under `design/canvases/pod-chief-mvp/` — one artboard
for the reports page with its tab strip and empty state; the tab labels and their order come from
that artboard. Until it exists, use the three keys in step 1 and the `EmptyState` molecule for the
body. `ReportsPage` is a **feature page**, not a registry component; it needs no
`design/registry/web.md` row.

## Contract
None. This story calls no API and adds no type to `specs/contracts/`. Report data is out of scope
for the MVP.

## Steps

1. `web/src/features/reports/types.ts` (new):
   `export const REPORT_SCOPES = ['pod', 'ward', 'sector'] as const;`
   `export type ReportScope = (typeof REPORT_SCOPES)[number];`
   `export const REPORT_TABS = ['summary', 'issues', 'performance'] as const;`
   `export type ReportTab = (typeof REPORT_TABS)[number];` No test.
2. `web/src/features/reports/ReportsPage.tsx` (new): takes `readonly scope: ReportScope`. Read
   `wardId` / `sectorId` from `useParams`, resolve the area name from `usePodSetup()`
   (`status.wards` / `status.sectors`), and fall back to the scope's own label when the id is
   unknown. Render `DashboardLayout` → `Breadcrumbs` (title = the scope title, items = Dashboard →
   Reports → the scope) → a `DataTableCard` with `columns={[]}`, `data={[]}`, `hidePagination`,
   `totalItems={0}`, a `tabs` config built from `REPORT_TABS` with `ariaLabel={t('reports.tabsLabel')}`,
   and `emptyMessage={<EmptyState title={t('reports.empty.title')} description={t('reports.empty.description')} />}`.
   Keep the active tab in the URL with `useSearchParams` (`?tab=`), defaulting to `summary` and
   ignoring an unknown value. Test: `web/src/features/reports/ReportsPage.test.tsx` —
   `should render the three report tabs`,
   `should show the ward name in the breadcrumb for a ward report`,
   `should put the selected tab in the query string`,
   `should fall back to the summary tab for an unknown tab value`.
3. `web/src/App.tsx`: point `/reports/general` at `<ReportsPage scope="pod" />`,
   `/reports/ward/:wardId` at `<ReportsPage scope="ward" />` and `/reports/sector/:sectorId` at
   `<ReportsPage scope="sector" />`, keeping each `ProtectedRoute` + `RoleGuard requiredRole="pod_admin"`
   wrapper exactly as it is. Leave the file-local `PlaceholderPage` in place for the routes that
   still use it; delete it only if no route references it any more (`web/CLAUDE.md`: no dead code).
   No separate test; step 2 and step 4 cover it.
4. `web/src/components/templates/Sidebar.test.tsx`: add
   `should list General plus one reports entry per ward under Reports for a pod chief`. No source
   change in this step — if the assertion fails, the bug is in `Sidebar.tsx` and belongs to this
   story; fix it there rather than weakening the test.
5. `web/src/locales/{en,af,zu}/translation.json`: add a `reports` block with `title`,
   `tabsLabel`, `scopes.pod`, `scopes.ward`, `scopes.sector`, `tabs.summary`, `tabs.issues`,
   `tabs.performance`, `empty.title`, `empty.description`. Reuse the existing `nav.reports` and
   `nav.generalReports` keys for the menu; do not duplicate them. Real Afrikaans and isiZulu
   translations, not English copies.

## Do not
- Do not add a report API, hook, query key or MSW handler. The page shows an empty state; that is
  the MVP.
- Do not hand-roll a `<Table>` or a `<Tabs>` strip. `DataTableCard` already owns tabs, toolbar and
  the empty state (`design/registry/web.md`: "Every admin list … Never hand-roll a table").
- Do not restructure `podChiefNavItems` or the dynamic ward/sector children in `Sidebar.tsx`; they
  already satisfy AC1 and AC2 and W13 depends on the same code path.
- Do not touch `/reports/heat` or `HeatReportPage`: that is W6, it is done, and it is a real report.
- Do not create one page component per scope. One `ReportsPage` with a `scope` prop, three routes.
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
  title: Pod chief opens the general pod report from the Reports menu
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/reports/general
  steps:
    - Log in as the pod chief and expand Reports in the sidebar.
    - Click General.
  expect: The page shows a "Pod reports" breadcrumb (Dashboard > Reports > Pod reports), a Summary/Issues/Performance tab strip with Summary active, and an empty state saying there is no report data yet.
- id: E2
  title: Pod chief opens a ward report from the Reports menu
  as: pod_chief
  services: [db, backend, web]
  url: http://localhost:3000/reports/general
  steps:
    - With Reports expanded, click a ward entry under Reports (for example Test Ward North).
    - Click the Issues tab.
  expect: The breadcrumb and page title show the ward's name instead of "Pod reports", the URL keeps ?tab=issues, and the Issues tab stays selected on refresh.
```
