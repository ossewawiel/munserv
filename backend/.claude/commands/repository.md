# JPA Repository Generator

name: "repository"
description: "Generate JPA repository with entity mapping"
parameters:
  - name: "name"
    description: "Entity name (e.g., 'Issue', 'Member')"
    required: true
  - name: "feature"
    description: "Feature module (e.g., 'issues', 'members')"
    required: true

---

You are an expert Kotlin developer generating repository layer code for the MunServ backend.

## Task

Generate a JPA repository for `{{name}}` in the `{{feature}}` module.

## Output Files

1. `src/main/kotlin/com/munserv/{{feature}}/repository/{{name}}Repository.kt` - Interface
2. `src/main/kotlin/com/munserv/{{feature}}/repository/{{name}}Entity.kt` - JPA Entity
3. `src/main/kotlin/com/munserv/{{feature}}/repository/Jpa{{name}}Repository.kt` - Implementation

## Repository Interface (Domain Layer Boundary)

```kotlin
package com.munserv.{{feature}}.repository

import com.munserv.{{feature}}.domain.{{name}}
import com.munserv.{{feature}}.domain.{{name}}Id

/**
 * Repository interface for {{name}} persistence.
 * Domain-facing interface - no JPA details exposed.
 */
interface {{name}}Repository {
    fun findById(id: {{name}}Id): {{name}}?
    fun findByIdForUpdate(id: {{name}}Id): {{name}}?
    fun findAll(): List<{{name}}>
    fun save(entity: {{name}}): {{name}}
    fun delete(id: {{name}}Id)
    fun existsById(id: {{name}}Id): Boolean
}
```

## JPA Entity

```kotlin
package com.munserv.{{feature}}.repository

import com.munserv.{{feature}}.domain.{{name}}
import com.munserv.{{feature}}.domain.{{name}}Id
import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

/**
 * JPA entity for {{name}} persistence.
 * Maps to database table and handles ORM concerns.
 */
@Entity
@Table(name = "{{name_snake}}s")
class {{name}}Entity(
    @Id
    val id: UUID,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant,

    @Column(name = "updated_at", nullable = false)
    val updatedAt: Instant,
) {
    /**
     * Convert JPA entity to domain entity.
     */
    fun toDomain(): {{name}} = {{name}}(
        id = {{name}}Id(id),
        createdAt = createdAt,
        updatedAt = updatedAt,
    )

    companion object {
        /**
         * Create JPA entity from domain entity.
         */
        fun fromDomain(domain: {{name}}): {{name}}Entity = {{name}}Entity(
            id = domain.id.value,
            createdAt = domain.createdAt,
            updatedAt = domain.updatedAt,
        )
    }
}
```

## Spring Data JPA Repository

```kotlin
package com.munserv.{{feature}}.repository

import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

/**
 * Spring Data JPA repository for {{name}}Entity.
 */
interface {{name}}JpaRepository : JpaRepository<{{name}}Entity, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT e FROM {{name}}Entity e WHERE e.id = :id")
    fun findByIdForUpdate(@Param("id") id: UUID): {{name}}Entity?
}
```

## Repository Implementation

```kotlin
package com.munserv.{{feature}}.repository

import com.munserv.{{feature}}.domain.{{name}}
import com.munserv.{{feature}}.domain.{{name}}Id
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository

/**
 * Implementation of {{name}}Repository using Spring Data JPA.
 */
@Repository
class Jpa{{name}}RepositoryImpl(
    private val jpa: {{name}}JpaRepository,
) : {{name}}Repository {

    override fun findById(id: {{name}}Id): {{name}}? =
        jpa.findByIdOrNull(id.value)?.toDomain()

    override fun findByIdForUpdate(id: {{name}}Id): {{name}}? =
        jpa.findByIdForUpdate(id.value)?.toDomain()

    override fun findAll(): List<{{name}}> =
        jpa.findAll().map { it.toDomain() }

    override fun save(entity: {{name}}): {{name}} =
        jpa.save({{name}}Entity.fromDomain(entity)).toDomain()

    override fun delete(id: {{name}}Id) {
        jpa.deleteById(id.value)
    }

    override fun existsById(id: {{name}}Id): Boolean =
        jpa.existsById(id.value)
}
```

## Repository Rules

1. **Interface Segregation** - Domain-facing interface with no JPA details
2. **Entity Mapping** - JPA annotations ONLY on Entity class
3. **Domain Conversion** - `toDomain()` and `fromDomain()` for mapping
4. **Pessimistic Locking** - Use `@Lock` for `findByIdForUpdate`
5. **Value Object Unwrapping** - Convert `{{name}}Id` to `UUID` for JPA

## Common JPA Patterns

### Custom Queries

```kotlin
@Query("SELECT e FROM {{name}}Entity e WHERE e.status = :status")
fun findByStatus(@Param("status") status: String): List<{{name}}Entity>

@Query("SELECT e FROM {{name}}Entity e WHERE e.createdAt > :since")
fun findCreatedAfter(@Param("since") since: Instant): List<{{name}}Entity>
```

### PostGIS Spatial Queries

```kotlin
@Query("""
    SELECT e FROM {{name}}Entity e
    WHERE ST_DWithin(e.location, ST_MakePoint(:lng, :lat), :meters)
""")
fun findWithinRadius(
    @Param("lat") lat: Double,
    @Param("lng") lng: Double,
    @Param("meters") meters: Double,
): List<{{name}}Entity>
```

### Pagination

```kotlin
fun findAll(pageable: Pageable): Page<{{name}}Entity>
```

## Entity Field Mapping Reference

| Domain Type | JPA Column | Annotation |
|-------------|------------|------------|
| `{{name}}Id` | `UUID` | `@Id` |
| `String` | `VARCHAR` | `@Column` |
| `Int` | `INTEGER` | `@Column` |
| `Instant` | `TIMESTAMP` | `@Column` |
| `GeoPoint` | `POINT` | `@Column(columnDefinition = "geography(Point,4326)")` |
| `Enum` | `VARCHAR` | `@Enumerated(EnumType.STRING)` |
| `SealedState` | `VARCHAR` | Store as string, convert manually |

## Output

Generate all three repository files with proper domain ↔ JPA entity conversion.
