# Service Class Generator

name: "service"
description: "Generate service class with sealed Result pattern"
parameters:
  - name: "name"
    description: "Service name (e.g., 'Issue', 'Member')"
    required: true
  - name: "feature"
    description: "Feature module (e.g., 'issues', 'members')"
    required: true
  - name: "operations"
    description: "Comma-separated operations (e.g., 'create,update,delete,findById')"
    required: true

---

You are an expert Kotlin developer generating service layer code for the MunServ backend.

## Task

Generate a service class for `{{name}}` in the `{{feature}}` module with operations: `{{operations}}`.

## Output Files

1. `src/main/kotlin/com/munserv/{{feature}}/service/{{name}}Service.kt`
2. `src/main/kotlin/com/munserv/{{feature}}/service/{{name}}Result.kt`
3. `src/main/kotlin/com/munserv/{{feature}}/service/{{name}}Commands.kt`

## Service Template

```kotlin
package com.munserv.{{feature}}.service

import com.munserv.{{feature}}.domain.{{name}}
import com.munserv.{{feature}}.domain.{{name}}Id
import com.munserv.{{feature}}.repository.{{name}}Repository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

/**
 * Service for managing {{name}} entities.
 * Handles business logic and coordinates between domain and repository.
 */
@Service
class {{name}}Service(
    private val repository: {{name}}Repository,
    private val clock: Clock,
) {
    private val logger = LoggerFactory.getLogger({{name}}Service::class.java)

    /**
     * Find a {{name}} by its ID.
     */
    fun findById(id: {{name}}Id): {{name}}Result =
        repository.findById(id)
            ?.let { {{name}}Result.Success(it) }
            ?: {{name}}Result.NotFound(id)

    /**
     * Find all {{name}} entities.
     */
    fun findAll(): List<{{name}}> = repository.findAll()

    /**
     * Create a new {{name}}.
     */
    @Transactional
    fun create(command: Create{{name}}Command): {{name}}Result {
        logger.info("Creating {{name}}: {}", command)

        val now = Instant.now(clock)
        val entity = {{name}}(
            id = {{name}}Id.generate(),
            // Map command fields to entity
            createdAt = now,
            updatedAt = now,
        )

        val saved = repository.save(entity)
        logger.info("Created {{name}} with id: {}", saved.id)
        return {{name}}Result.Success(saved)
    }

    /**
     * Update an existing {{name}}.
     */
    @Transactional
    fun update(id: {{name}}Id, command: Update{{name}}Command): {{name}}Result {
        val existing = repository.findByIdForUpdate(id)
            ?: return {{name}}Result.NotFound(id)

        val updated = existing
            // Apply updates from command
            .withUpdatedAt(Instant.now(clock))

        val saved = repository.save(updated)
        logger.info("Updated {{name}}: {}", saved.id)
        return {{name}}Result.Success(saved)
    }

    /**
     * Delete a {{name}} by ID.
     */
    @Transactional
    fun delete(id: {{name}}Id): {{name}}Result {
        val existing = repository.findById(id)
            ?: return {{name}}Result.NotFound(id)

        repository.delete(id)
        logger.info("Deleted {{name}}: {}", id)
        return {{name}}Result.Success(existing)
    }
}
```

## Result Template

```kotlin
package com.munserv.{{feature}}.service

import com.munserv.{{feature}}.domain.{{name}}
import com.munserv.{{feature}}.domain.{{name}}Id

/**
 * Sealed result type for {{name}} operations.
 * Used instead of exceptions for expected failure cases.
 */
sealed interface {{name}}Result {
    /** Operation succeeded with the resulting entity. */
    data class Success(val {{nameLower}}: {{name}}) : {{name}}Result

    /** Entity with given ID was not found. */
    data class NotFound(val id: {{name}}Id) : {{name}}Result

    /** Validation failed with error messages. */
    data class ValidationError(val errors: List<String>) : {{name}}Result

    /** User is not authorized for this operation. */
    data class Unauthorized(val reason: String) : {{name}}Result

    /** Invalid state transition attempted. */
    data class InvalidOperation(val reason: String) : {{name}}Result
}
```

## Commands Template

```kotlin
package com.munserv.{{feature}}.service

/**
 * Command to create a new {{name}}.
 */
data class Create{{name}}Command(
    // Add creation fields
)

/**
 * Command to update an existing {{name}}.
 */
data class Update{{name}}Command(
    // Add update fields
)
```

## Service Rules

1. **Constructor Injection** - All dependencies via constructor (no @Autowired fields)
2. **Sealed Results** - Return `{{name}}Result` instead of throwing exceptions
3. **Transactional** - Mark mutating methods with `@Transactional`
4. **Clock Injection** - Use injected `Clock` for timestamps (testability)
5. **Logging** - Log at INFO for operations, DEBUG for details
6. **Find For Update** - Use `findByIdForUpdate()` for concurrent safety in updates

## Pattern Reference

```kotlin
// ✅ Correct - Return result for not found
val entity = repository.findById(id)
    ?: return {{name}}Result.NotFound(id)

// ✅ Correct - Chain results with let
repository.findById(id)
    ?.let { {{name}}Result.Success(it) }
    ?: {{name}}Result.NotFound(id)

// ❌ Wrong - Throw exception
val entity = repository.findById(id)
    ?: throw NotFoundException("{{name}} not found: $id")
```

## Output

Generate the service files based on the `{{operations}}` parameter:
- `findById` → Add findById method
- `findAll` → Add findAll method
- `create` → Add create method + Create command
- `update` → Add update method + Update command
- `delete` → Add delete method
