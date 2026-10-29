# Feature Module Scaffolder

name: "feature"
description: "Scaffold complete feature module with all layers"
parameters:
  - name: "name"
    description: "Feature name (e.g., 'notifications', 'reports')"
    required: true
  - name: "entities"
    description: "Comma-separated entity names (e.g., 'Notification,NotificationType')"
    required: false

---

You are an expert Kotlin developer scaffolding a new feature module for the MunServ backend.

## Task

Create a complete feature module `{{name}}` with the standard layer structure.

## Directory Structure to Create

```
src/main/kotlin/com/munserv/{{name}}/
├── api/
│   ├── {{Name}}Controller.kt
│   ├── {{Name}}Request.kt
│   └── {{Name}}Response.kt
├── domain/
│   ├── {{Name}}.kt            ← Domain entity
│   ├── {{Name}}Id.kt          ← Value object
│   └── {{Name}}Type.kt        ← Enum (if needed)
├── service/
│   ├── {{Name}}Service.kt
│   └── {{Name}}Result.kt      ← Sealed result
└── repository/
    ├── {{Name}}Repository.kt  ← Interface
    ├── {{Name}}Entity.kt      ← JPA entity
    └── Jpa{{Name}}Repository.kt

src/test/kotlin/com/munserv/{{name}}/
├── domain/
│   └── {{Name}}Test.kt
├── service/
│   └── {{Name}}ServiceTest.kt
└── api/
    └── {{Name}}ApiContractTest.kt
```

## File Templates

### domain/{{Name}}Id.kt
```kotlin
package com.munserv.{{name}}.domain

import java.util.UUID

@JvmInline
value class {{Name}}Id(val value: UUID) {
    companion object {
        fun generate(): {{Name}}Id = {{Name}}Id(UUID.randomUUID())
        fun fromString(value: String): {{Name}}Id = {{Name}}Id(UUID.fromString(value))
    }
    override fun toString(): String = value.toString()
}
```

### domain/{{Name}}.kt
```kotlin
package com.munserv.{{name}}.domain

import java.time.Instant

data class {{Name}}(
    val id: {{Name}}Id,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    fun withUpdatedAt(timestamp: Instant): {{Name}} = copy(updatedAt = timestamp)
}
```

### service/{{Name}}Result.kt
```kotlin
package com.munserv.{{name}}.service

import com.munserv.{{name}}.domain.{{Name}}
import com.munserv.{{name}}.domain.{{Name}}Id

sealed interface {{Name}}Result {
    data class Success(val {{name}}: {{Name}}) : {{Name}}Result
    data class NotFound(val id: {{Name}}Id) : {{Name}}Result
    data class ValidationError(val errors: List<String>) : {{Name}}Result
    data class Unauthorized(val reason: String) : {{Name}}Result
}
```

### service/{{Name}}Service.kt
```kotlin
package com.munserv.{{name}}.service

import com.munserv.{{name}}.domain.{{Name}}
import com.munserv.{{name}}.domain.{{Name}}Id
import com.munserv.{{name}}.repository.{{Name}}Repository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Clock
import java.time.Instant

@Service
class {{Name}}Service(
    private val repository: {{Name}}Repository,
    private val clock: Clock,
) {
    fun findById(id: {{Name}}Id): {{Name}}Result =
        repository.findById(id)
            ?.let { {{Name}}Result.Success(it) }
            ?: {{Name}}Result.NotFound(id)

    fun findAll(): List<{{Name}}> = repository.findAll()

    @Transactional
    fun create(command: Create{{Name}}Command): {{Name}}Result {
        val now = Instant.now(clock)
        val entity = {{Name}}(
            id = {{Name}}Id.generate(),
            createdAt = now,
            updatedAt = now,
        )
        return {{Name}}Result.Success(repository.save(entity))
    }
}

data class Create{{Name}}Command(
    // Add command fields
)
```

### repository/{{Name}}Repository.kt
```kotlin
package com.munserv.{{name}}.repository

import com.munserv.{{name}}.domain.{{Name}}
import com.munserv.{{name}}.domain.{{Name}}Id

interface {{Name}}Repository {
    fun findById(id: {{Name}}Id): {{Name}}?
    fun findAll(): List<{{Name}}>
    fun save(entity: {{Name}}): {{Name}}
    fun delete(id: {{Name}}Id)
}
```

### repository/{{Name}}Entity.kt
```kotlin
package com.munserv.{{name}}.repository

import com.munserv.{{name}}.domain.{{Name}}
import com.munserv.{{name}}.domain.{{Name}}Id
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "{{name}}s")
class {{Name}}Entity(
    @Id
    val id: UUID,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,

    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
) {
    fun toDomain(): {{Name}} = {{Name}}(
        id = {{Name}}Id(id),
        createdAt = createdAt,
        updatedAt = updatedAt,
    )

    companion object {
        fun fromDomain(domain: {{Name}}): {{Name}}Entity = {{Name}}Entity(
            id = domain.id.value,
            createdAt = domain.createdAt,
            updatedAt = domain.updatedAt,
        )
    }
}
```

### api/{{Name}}Controller.kt
```kotlin
package com.munserv.{{name}}.api

import com.munserv.{{name}}.domain.{{Name}}Id
import com.munserv.{{name}}.service.{{Name}}Result
import com.munserv.{{name}}.service.{{Name}}Service
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1/{{name}}s")
@Tag(name = "{{Name}}s", description = "{{Name}} management endpoints")
class {{Name}}Controller(
    private val service: {{Name}}Service,
) {
    @GetMapping("/{id}")
    @Operation(summary = "Get {{name}} by ID")
    fun getById(@PathVariable id: UUID): ResponseEntity<{{Name}}Response> =
        when (val result = service.findById({{Name}}Id(id))) {
            is {{Name}}Result.Success -> ResponseEntity.ok(result.{{name}}.toResponse())
            is {{Name}}Result.NotFound -> ResponseEntity.notFound().build()
            else -> ResponseEntity.internalServerError().build()
        }

    @GetMapping
    @Operation(summary = "List all {{name}}s")
    fun list(): ResponseEntity<List<{{Name}}Response>> =
        ResponseEntity.ok(service.findAll().map { it.toResponse() })
}
```

## Layer Rules

| Layer | Can Import | Cannot Import |
|-------|------------|---------------|
| domain | java.*, kotlin.* | Spring, JPA, other modules |
| service | domain, repository interfaces | JPA entities, controllers |
| repository | domain, JPA | service, controllers |
| api | service, domain | repository, JPA entities |

## Output

1. Create all directories
2. Generate all files from templates
3. Adjust based on `{{entities}}` if provided
4. Follow existing module patterns from `issues/` as reference
