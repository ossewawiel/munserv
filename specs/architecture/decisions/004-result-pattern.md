# ADR-004: Sealed Result types instead of exceptions for business outcomes

**Date:** 2024-12 (recorded 2026-09-05)
**Status:** Accepted

## Context
Expected failures (not found, invalid transition, validation) were leaking as exceptions and HTTP mapping was scattered.

## Decision
Every service method returns a sealed result (`Success`, `NotFound`, `InvalidTransition`, `ValidationError`, ...). Controllers exhaustively `when` over it. Mobile mirrors this with a Freezed `Result<T>`; web with a `Result` union. Exceptions are reserved for programming errors and infrastructure faults.

## Consequences
✅ Every outcome is visible in the type; the compiler enforces handling.
✅ HTTP status mapping lives in one place per endpoint.
⚠️ More types to write; the `/service` and `/controller` skills scaffold them.
