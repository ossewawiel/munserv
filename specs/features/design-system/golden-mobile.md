---
issue: 0
story: DS4b
title: "Golden tests for the mobile design system"
platform: mobile
status: pending
depends_on: []
touches: [design-system, mobile-goldens]
created_by: orchestrator
created_at: "2026-09-05"
files_changed: []
tests_added: []
---

# DS4b · Golden tests (Mobile)

Read `design/README.md` and `design/registry/mobile.md`. This handoff is complete on its own.

## Outcome
`flutter test test/goldens` renders every shared widget and `IssueCard` variant in light and dark theme and compares against committed golden PNGs; `flutter test test/goldens --update-goldens` refreshes them. CI runs them as part of `flutter test` and refuses a PR that changes goldens unless it carries the `design-approved` label.

## Acceptance criteria
- [ ] `mobile/test/goldens/` with one test file per registry row (shared widgets, `IssueCard` variants, `HeatIndicator` levels, `IssueTypeIcon` types, `EmptyState` factories), each pumping the widget inside `MaterialApp(theme: AppTheme.light / dark)` and a `ProviderScope` with the fixtures from `widgetbook/fixtures.dart` (move shared fixtures to `test/goldens/fixtures.dart` if importing from `widgetbook/` is awkward, and make Widgetbook import from there)
- [ ] Deterministic rendering: a `test/goldens/golden_test_helper.dart` that sets a fixed surface size (390×844 and a widget-sized variant), `debugDisableShadows = true`, and loads the app's font files (google_fonts is disabled in tests: `GoogleFonts.config.allowRuntimeFetching = false`) so text renders identically on the developer's Linux machine and on the Linux CI runner
- [ ] Golden files committed under `test/goldens/**/*.png`, named `<widget>_<state>_<light|dark>.png`
- [ ] `.github/workflows/ci.yml`: in the mobile job, a step that fails when `git diff --name-only origin/master...HEAD` contains `mobile/test/goldens/` PNGs and the PR has no `design-approved` label
- [ ] `flutter test` passes locally and the goldens are not flaky across two consecutive runs

## Contract
None.

## Steps
1. `mobile/test/goldens/golden_test_helper.dart`: `pumpGolden(WidgetTester, Widget, {bool dark, Size})` and a `setUpAll` font loader (`loadAppFonts` pattern: read `.ttf` from the `google_fonts` cache is not allowed; use the font assets already bundled or fall back to the default test font consistently and say which).
2. One test per registry row using `matchesGoldenFile('goldens/<name>.png')`, light and dark.
3. `flutter test test/goldens --update-goldens`, then `flutter test test/goldens` twice; commit the PNGs.
4. `.github/workflows/ci.yml`: the baseline-guard step in the mobile job (mirror the web one: `gh pr view` labels, `design-approved`).
5. `mobile/CLAUDE.md`: one line under Tests; `design/README.md`: the two commands under "Sign-off" (the web handoff adds its own lines; append, do not overwrite).

## Do not
- Do not change any widget to make a golden stable; skip the widget with a reason instead.
- Do not touch `web/`, `backend/`, `design/tokens/`.

## Done when
```bash
# every command must exit 0 before you finish; run this block once at the end
cd mobile && dart format --set-exit-if-changed lib test widgetbook && flutter analyze --fatal-infos && flutter test && flutter test test/goldens
```
Then update the frontmatter (`status: completed`, `files_changed`, `tests_added`) and end with the golden count, the font strategy chosen, and anything skipped. If you cannot finish, set `status: blocked` and end with `BLOCKED: <reason>`.
