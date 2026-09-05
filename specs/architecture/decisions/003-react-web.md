# ADR-003: React + TypeScript + MUI for the admin portal

**Date:** 2024-12 (recorded 2026-09-05)
**Status:** Accepted

## Context
Administrators need a data-heavy portal: tables, dashboards, maps, forms, role-based navigation, and per-pod theming.

## Decision
React 19 with TypeScript, Vite, MUI (Material UI) with the `sx` prop as the only styling mechanism, React Query for server state, react-i18next for text, Vitest and Playwright for tests.

## Consequences
✅ MUI's component breadth and theming carry the pod-branding requirement.
✅ React Query removes hand-written fetching state and cache handling.
⚠️ MUI majors bring codemods (v9 removed system props and `*Props`); upgrades are planned work, not drift.
