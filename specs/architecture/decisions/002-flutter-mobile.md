# ADR-002: Flutter for the member app

**Date:** 2024-12 (recorded 2026-09-05)
**Status:** Accepted

## Context
Members report issues from Android and iOS phones with camera, GPS and maps; one maintainer cannot keep two native code bases.

## Decision
Flutter with Riverpod for state, Freezed for models, go_router for navigation, flutter_map for maps, Material 3 theming.

## Consequences
✅ One code base, native performance, strong camera and map packages.
✅ Riverpod plus Freezed give immutable models and testable providers without boilerplate.
⚠️ Code generation (build_runner) is a required step after model or provider changes.
