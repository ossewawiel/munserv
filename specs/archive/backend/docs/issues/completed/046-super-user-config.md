---
issue: 46
title: "Super user configuration via environment"
platform: backend
status: completed
created_by: central-agent
created_at: 2026-01-26
updated_at: 2026-01-26
dependencies: []
files_changed:
  - src/main/kotlin/com/munserv/bootstrap/config/BootstrapConfig.kt
  - src/main/resources/application.yml
  - src/main/resources/application-local.yml
tests_added:
  - src/test/kotlin/com/munserv/bootstrap/config/BootstrapConfigTest.kt
commits: []
blockers: []
---

# Issue #46: Super user configuration via environment (Backend)

## Context

When a fresh pod is deployed, there are no admin accounts. A 'super user' (configuration-based credentials from environment variables) can log in to create the first Pod Chief. This story implements the configuration infrastructure for super user credentials.

## What To Fix

Create `BootstrapConfig.kt` configuration class following the `AdminConfig` pattern.

### Files To Create

- `src/main/kotlin/com/munserv/bootstrap/config/BootstrapConfig.kt`

### Files To Modify

- `src/main/resources/application.yml` - Add bootstrap configuration section
- `src/main/resources/application-local.yml` - Add dev defaults

### Implementation Details

#### 1. BootstrapConfig.kt

```kotlin
package com.munserv.bootstrap.config

import org.springframework.boot.context.properties.ConfigurationProperties

/**
 * Configuration properties for super user bootstrap access.
 *
 * Used to configure the super user who can create the first Pod Chief
 * on a fresh pod deployment. After Pod Chief completes onboarding,
 * the super user loses access.
 *
 * SECURITY:
 * - enabled defaults to false (must explicitly enable)
 * - Credentials must be set via environment variables
 * - Never log credentials
 *
 * Environment variables:
 * - BOOTSTRAP_SUPER_USER_ENABLED
 * - SUPER_USER_EMAIL
 * - SUPER_USER_PASSWORD
 */
@ConfigurationProperties(prefix = "bootstrap.super-user")
data class BootstrapConfig(
    /** Whether super user bootstrap is enabled */
    val enabled: Boolean = false,

    /** Super user email address for authentication */
    val email: String? = null,

    /** Super user password */
    val password: String? = null
) {
    /**
     * Check if super user is properly configured.
     * Returns true only if enabled and both credentials are set.
     */
    fun isConfigured(): Boolean = enabled && !email.isNullOrBlank() && !password.isNullOrBlank()
}
```

#### 2. application.yml additions

Add after the `admin:` section:

```yaml
# Bootstrap Super User Configuration
# Used for creating the first Pod Chief on a fresh pod deployment.
# SECURITY: Disabled by default. Enable only during initial setup.
bootstrap:
  super-user:
    enabled: ${BOOTSTRAP_SUPER_USER_ENABLED:false}
    email: ${SUPER_USER_EMAIL:}
    password: ${SUPER_USER_PASSWORD:}
```

#### 3. application-local.yml additions

Add for local development:

```yaml
# Bootstrap super user for local development
# WARNING: Development only - never use these in production
bootstrap:
  super-user:
    enabled: true
    email: superuser@munserv.local
    password: super123
```

## Acceptance Criteria

- [ ] `BootstrapConfig.kt` created with `@ConfigurationProperties(prefix = "bootstrap.super-user")`
- [ ] `enabled` property defaults to `false`
- [ ] `email` property reads from `SUPER_USER_EMAIL` env var
- [ ] `password` property reads from `SUPER_USER_PASSWORD` env var
- [ ] `isConfigured()` method returns true only when enabled AND credentials are set
- [ ] Configuration added to `application.yml` with env var bindings
- [ ] Dev defaults added to `application-local.yml`
- [ ] Tests pass

## Test Requirements

Create test file: `src/test/kotlin/com/munserv/bootstrap/config/BootstrapConfigTest.kt`

```kotlin
class BootstrapConfigTest {

    @Test
    fun `isConfigured returns false when disabled`() {
        val config = BootstrapConfig(enabled = false, email = "test@test.com", password = "pass")
        assertThat(config.isConfigured()).isFalse()
    }

    @Test
    fun `isConfigured returns false when email is null`() {
        val config = BootstrapConfig(enabled = true, email = null, password = "pass")
        assertThat(config.isConfigured()).isFalse()
    }

    @Test
    fun `isConfigured returns false when email is blank`() {
        val config = BootstrapConfig(enabled = true, email = "  ", password = "pass")
        assertThat(config.isConfigured()).isFalse()
    }

    @Test
    fun `isConfigured returns false when password is null`() {
        val config = BootstrapConfig(enabled = true, email = "test@test.com", password = null)
        assertThat(config.isConfigured()).isFalse()
    }

    @Test
    fun `isConfigured returns false when password is blank`() {
        val config = BootstrapConfig(enabled = true, email = "test@test.com", password = "  ")
        assertThat(config.isConfigured()).isFalse()
    }

    @Test
    fun `isConfigured returns true when enabled and credentials set`() {
        val config = BootstrapConfig(enabled = true, email = "test@test.com", password = "pass")
        assertThat(config.isConfigured()).isTrue()
    }

    @Test
    fun `default values are secure`() {
        val config = BootstrapConfig()
        assertThat(config.enabled).isFalse()
        assertThat(config.email).isNull()
        assertThat(config.password).isNull()
        assertThat(config.isConfigured()).isFalse()
    }
}
```

## Dependencies

- None - this is the first story in the bootstrap feature

## Implementation Notes

### Completed: 2026-01-26

**Files Created:**
- `src/main/kotlin/com/munserv/bootstrap/config/BootstrapConfig.kt` - Configuration class with @ConfigurationProperties
- `src/test/kotlin/com/munserv/bootstrap/config/BootstrapConfigTest.kt` - 7 unit tests

**Files Modified:**
- `src/main/resources/application.yml` - Added bootstrap.super-user config section
- `src/main/resources/application-local.yml` - Added dev defaults for local testing

**Verification:**
- All 7 BootstrapConfigTest tests pass
- ktlint check passes
- Configuration auto-discovered via @ConfigurationPropertiesScan

**Usage:**
```bash
# Production: Set environment variables
export BOOTSTRAP_SUPER_USER_ENABLED=true
export SUPER_USER_EMAIL=admin@example.com
export SUPER_USER_PASSWORD=secure-password

# Local dev: Uses application-local.yml defaults
# superuser@munserv.local / super123
```
