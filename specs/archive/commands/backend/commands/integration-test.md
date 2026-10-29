# Integration Test Generator

name: "integration-test"
description: "Generate integration tests with TestContainers"
parameters:
  - name: "target"
    description: "File path to test (e.g., 'issues/repository/IssueRepository.kt')"
    required: true
  - name: "type"
    description: "Test type: repository, scenario"
    required: true

---

You are an expert Kotlin developer writing integration tests for the MunServ backend.

## Task

Generate integration tests for `{{target}}` (type: `{{type}}`).

## Output Location

- Repository: `src/test/kotlin/com/munserv/{{feature}}/repository/{{Name}}RepositoryTest.kt`
- Scenario: `src/test/kotlin/com/munserv/integration/scenarios/{{Name}}ScenarioTest.kt`

## Test Framework Stack

- **JUnit 5** - Test framework
- **TestContainers** - PostgreSQL + PostGIS container
- **Spring Boot Test** - Integration context
- **Kotest** - Assertions

## Repository Integration Test Template

```kotlin
package com.munserv.{{feature}}.repository

import com.munserv.{{feature}}.domain.{{Name}}
import com.munserv.{{feature}}.domain.{{Name}}Id
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import org.testcontainers.utility.DockerImageName
import java.time.Instant
import java.util.UUID

@DataJpaTest
@Testcontainers
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(Jpa{{Name}}RepositoryImpl::class)
class {{Name}}RepositoryTest {

    companion object {
        @Container
        val postgres = PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:15-3.3-alpine")
                .asCompatibleSubstituteFor("postgres")
        ).apply {
            withDatabaseName("test_db")
            withUsername("test")
            withPassword("test")
        }

        @JvmStatic
        @DynamicPropertySource
        fun configureProperties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url") { postgres.jdbcUrl }
            registry.add("spring.datasource.username") { postgres.username }
            registry.add("spring.datasource.password") { postgres.password }
        }
    }

    @Autowired
    private lateinit var repository: {{Name}}Repository

    @Autowired
    private lateinit var jpaRepository: {{Name}}JpaRepository

    private val testId = {{Name}}Id(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testCreatedAt = Instant.parse("2025-01-01T10:00:00Z")

    private fun createTest{{Name}}(
        id: {{Name}}Id = {{Name}}Id.generate(),
    ) = {{Name}}(
        id = id,
        createdAt = testCreatedAt,
        updatedAt = testCreatedAt,
    )

    @BeforeEach
    fun setUp() {
        jpaRepository.deleteAll()
    }

    @Nested
    inner class Save {
        @Test
        fun `should persist and retrieve {{name}}`() {
            // Arrange
            val entity = createTest{{Name}}()

            // Act
            val saved = repository.save(entity)
            val found = repository.findById(saved.id)

            // Assert
            found shouldNotBe null
            found!!.id shouldBe saved.id
            found.createdAt shouldBe entity.createdAt
        }
    }

    @Nested
    inner class FindById {
        @Test
        fun `should return null when not found`() {
            val result = repository.findById(testId)
            result shouldBe null
        }

        @Test
        fun `should return entity when exists`() {
            // Arrange
            val entity = createTest{{Name}}(id = testId)
            repository.save(entity)

            // Act
            val result = repository.findById(testId)

            // Assert
            result shouldNotBe null
            result!!.id shouldBe testId
        }
    }

    @Nested
    inner class FindAll {
        @Test
        fun `should return empty list when no entities`() {
            val result = repository.findAll()
            result shouldHaveSize 0
        }

        @Test
        fun `should return all entities`() {
            // Arrange
            repository.save(createTest{{Name}}())
            repository.save(createTest{{Name}}())

            // Act
            val result = repository.findAll()

            // Assert
            result shouldHaveSize 2
        }
    }

    @Nested
    inner class Delete {
        @Test
        fun `should remove entity`() {
            // Arrange
            val entity = createTest{{Name}}(id = testId)
            repository.save(entity)

            // Act
            repository.delete(testId)

            // Assert
            repository.findById(testId) shouldBe null
        }
    }
}
```

## Scenario Integration Test Template

```kotlin
package com.munserv.integration.scenarios

import com.munserv.{{feature}}.domain.{{Name}}
import com.munserv.{{feature}}.domain.{{Name}}Id
import com.munserv.{{feature}}.service.{{Name}}Result
import com.munserv.{{feature}}.service.{{Name}}Service
import com.munserv.{{feature}}.service.Create{{Name}}Command
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.springframework.transaction.annotation.Transactional
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import org.testcontainers.utility.DockerImageName

/**
 * End-to-end scenario test for {{Name}} workflow.
 * Tests the full flow through all layers with a real database.
 */
@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
@Transactional
class {{Name}}WorkflowScenarioTest {

    companion object {
        @Container
        val postgres = PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:15-3.3-alpine")
                .asCompatibleSubstituteFor("postgres")
        ).apply {
            withDatabaseName("test_db")
            withUsername("test")
            withPassword("test")
        }

        @JvmStatic
        @DynamicPropertySource
        fun configureProperties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url") { postgres.jdbcUrl }
            registry.add("spring.datasource.username") { postgres.username }
            registry.add("spring.datasource.password") { postgres.password }
        }
    }

    @Autowired
    private lateinit var service: {{Name}}Service

    @Test
    fun `should complete full {{name}} lifecycle`() {
        // Step 1: Create
        val createResult = service.create(Create{{Name}}Command())
        createResult.shouldBeInstanceOf<{{Name}}Result.Success>()
        val created = (createResult as {{Name}}Result.Success).{{nameLower}}

        // Step 2: Find by ID
        val findResult = service.findById(created.id)
        findResult.shouldBeInstanceOf<{{Name}}Result.Success>()
        (findResult as {{Name}}Result.Success).{{nameLower}}.id shouldBe created.id

        // Step 3: Update
        // Add update steps based on entity

        // Step 4: Verify in list
        val all = service.findAll()
        all.any { it.id == created.id } shouldBe true
    }
}
```

## TestContainers Configuration

### PostgreSQL + PostGIS

```kotlin
@Container
val postgres = PostgreSQLContainer(
    DockerImageName.parse("postgis/postgis:15-3.3-alpine")
        .asCompatibleSubstituteFor("postgres")
).apply {
    withDatabaseName("test_db")
    withUsername("test")
    withPassword("test")
}
```

### Dynamic Properties

```kotlin
@JvmStatic
@DynamicPropertySource
fun configureProperties(registry: DynamicPropertyRegistry) {
    registry.add("spring.datasource.url") { postgres.jdbcUrl }
    registry.add("spring.datasource.username") { postgres.username }
    registry.add("spring.datasource.password") { postgres.password }
}
```

## Integration Test Annotations

| Annotation | Purpose |
|------------|---------|
| `@DataJpaTest` | JPA slice test (repositories only) |
| `@SpringBootTest` | Full application context |
| `@Testcontainers` | Enable TestContainers |
| `@ActiveProfiles("test")` | Use test profile |
| `@Transactional` | Rollback after each test |
| `@AutoConfigureTestDatabase(replace = NONE)` | Use TestContainers DB |
| `@Import(...)` | Import additional beans |

## Test Rules

1. **Real Database** - Use TestContainers PostgreSQL + PostGIS
2. **Cleanup** - Clean data between tests with `@Transactional` or `@BeforeEach`
3. **Isolation** - Each test should be independent
4. **Meaningful Scenarios** - Test realistic user workflows
5. **Verify Persistence** - Check data is actually saved/retrieved

## Output

Generate integration test based on `{{type}}`:
- `repository` → Test repository with real database
- `scenario` → Test end-to-end workflow
