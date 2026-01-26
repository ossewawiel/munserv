# Investigation: Super user configuration via environment

**Issue:** #46 (B5)
**Date:** 2026-01-26
**Platforms:** Backend

## Problem Statement

When a fresh pod is deployed, there are no admin accounts. A 'super user' must be able to log in to create the first Pod Chief. The super user credentials need to come from environment variables, not from code or database.

## Investigation Steps

1. Reviewed existing `AdminConfig` pattern in `auth/config/AdminConfig.kt`
2. Checked `application.yml` for existing configuration structure
3. Confirmed `@ConfigurationPropertiesScan` is enabled in `MunServApplication.kt`
4. Verified no existing bootstrap module exists

## Current State

- `AdminConfig` provides MVP admin configuration via `admin.*` properties
- Application uses `@ConfigurationPropertiesScan` to auto-discover config classes
- Environment variables can override yaml defaults using Spring Boot conventions

## Affected Components

### Backend
- New file: `src/main/kotlin/com/munserv/bootstrap/config/BootstrapConfig.kt`
- Modified: `src/main/resources/application.yml` (add bootstrap config)
- Modified: `src/main/resources/application-local.yml` (add dev defaults)

## Implementation Approach

1. Create `BootstrapConfig.kt` with `@ConfigurationProperties(prefix = "bootstrap.super-user")`
2. Add `enabled` flag (default: false for safety)
3. Add `email` and `password` properties with no defaults
4. Add yaml configuration section with env var bindings
5. Add local defaults for development in `application-local.yml`

## Security Considerations

- Default `enabled: false` to prevent accidental activation in production
- No default credentials - must be explicitly set
- Never log credentials (covered by B7 audit logging story)
- Credentials should only exist in environment, never committed
