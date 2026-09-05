# ADR-005: Feature folders on every platform

**Date:** 2024-12 (recorded 2026-09-05)
**Status:** Accepted

## Context
Layer-first layouts (all controllers together, all services together) scatter one feature across the tree and make agent handoffs list many unrelated paths.

## Decision
Group by domain feature: `com.munserv.<feature>/{api,domain,service,repository}` in the backend, `src/features/<feature>/{api,hooks,types,components}` on web, `lib/features/<feature>/{data,domain,providers,presentation}` on mobile. Shared code lives in `shared/`.

## Consequences
✅ A story's handoff names one folder per platform.
✅ Cross-module coupling is visible as imports across feature packages and is reviewed.
⚠️ Deciding what is "shared" needs judgement; the rule is extract at the second use.
