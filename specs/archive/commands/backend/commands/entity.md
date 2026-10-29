# Domain Entity Generator

name: "entity"
description: "Generate domain entity, value object, or sealed state class"
parameters:
  - name: "name"
    description: "Entity name (e.g., 'Issue', 'Member', 'Sector')"
    required: true
  - name: "feature"
    description: "Feature module (e.g., 'issues', 'members', 'sectors')"
    required: true
  - name: "type"
    description: "Type: entity, value-object, state-machine"
    required: true

---

You are an expert Kotlin developer generating domain layer code for the MunServ backend.

## Task

Generate a `{{type}}` named `{{name}}` in the `{{feature}}` module.

## Output Location

`src/main/kotlin/com/munserv/{{feature}}/domain/{{name}}.kt`

## Patterns by Type

### Value Object (Type-Safe ID)

```kotlin
package com.munserv.{{feature}}.domain

import java.util.UUID

/**
 * Type-safe identifier for {{name}}.
 * Prevents mixing IDs from different entity types.
 */
@JvmInline
value class {{name}}Id(val value: UUID) {
    companion object {
        fun generate(): {{name}}Id = {{name}}Id(UUID.randomUUID())
        fun fromString(value: String): {{name}}Id = {{name}}Id(UUID.fromString(value))
    }

    override fun toString(): String = value.toString()
}
```

### Domain Entity

```kotlin
package com.munserv.{{feature}}.domain

import java.time.Instant

/**
 * Domain entity representing a {{name}}.
 *
 * This is a pure domain class with no framework dependencies.
 * All updates are immutable via copy() methods.
 */
data class {{name}}(
    val id: {{name}}Id,
    // Add other properties here
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    /**
     * Returns a new {{name}} with the updated timestamp.
     */
    fun withUpdatedAt(timestamp: Instant): {{name}} = copy(updatedAt = timestamp)

    // Add other business methods here
}
```

### Sealed State Machine

```kotlin
package com.munserv.{{feature}}.domain

/**
 * State machine for {{name}}.
 * Defines allowed state transitions.
 */
sealed class {{name}}State {
    abstract val isOpen: Boolean
    abstract val isClosed: Boolean
    abstract fun canTransitionTo(newState: {{name}}State): Boolean

    data object Initial : {{name}}State() {
        override val isOpen = true
        override val isClosed = false
        override fun canTransitionTo(newState: {{name}}State) = when (newState) {
            is Active, is Cancelled -> true
            else -> false
        }
    }

    data object Active : {{name}}State() {
        override val isOpen = true
        override val isClosed = false
        override fun canTransitionTo(newState: {{name}}State) = when (newState) {
            is Completed, is Cancelled -> true
            else -> false
        }
    }

    data object Completed : {{name}}State() {
        override val isOpen = false
        override val isClosed = true
        override fun canTransitionTo(newState: {{name}}State) = false
    }

    data object Cancelled : {{name}}State() {
        override val isOpen = false
        override val isClosed = true
        override fun canTransitionTo(newState: {{name}}State) = false
    }

    companion object {
        fun fromString(value: String): {{name}}State = when (value.lowercase()) {
            "initial" -> Initial
            "active" -> Active
            "completed" -> Completed
            "cancelled" -> Cancelled
            else -> throw IllegalArgumentException("Unknown {{name}}State: $value")
        }
    }
}
```

## Rules

1. **Domain Purity** - No framework annotations (JPA, Spring) in domain classes
2. **Immutability** - Use `val` only, mutations via `copy()` with helper methods
3. **Value Classes** - Use `@JvmInline value class` for all IDs
4. **Sealed Classes** - Use for state machines with `canTransitionTo()` logic
5. **Companion Objects** - Add factory methods like `generate()`, `fromString()`
6. **KDoc Comments** - Document public classes and methods

## Checklist

- [ ] Package is `com.munserv.{{feature}}.domain`
- [ ] No framework imports (Spring, JPA, Jackson)
- [ ] All properties are `val`
- [ ] Has KDoc documentation
- [ ] Value objects have `generate()` and `fromString()` companions
- [ ] State machines have `canTransitionTo()` method
- [ ] Entities have immutable update methods (`withX()`)

## Output

Generate the Kotlin file based on the `{{type}}` parameter, following the patterns above.
