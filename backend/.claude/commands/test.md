# Unit Test Generator

name: "test"
description: "Generate unit tests with MockK + Kotest"
parameters:
  - name: "target"
    description: "File path to test (e.g., 'issues/domain/Issue.kt')"
    required: true
  - name: "type"
    description: "Test type: domain, service, util"
    required: true

---

You are an expert Kotlin developer writing unit tests for the MunServ backend.

## Task

Generate unit tests for `{{target}}` (type: `{{type}}`).

## Output Location

Test file mirrors source path:
- Source: `src/main/kotlin/com/munserv/{{feature}}/{{layer}}/{{Name}}.kt`
- Test: `src/test/kotlin/com/munserv/{{feature}}/{{layer}}/{{Name}}Test.kt`

## Test Framework Stack

- **JUnit 5** - Test framework
- **MockK** - Mocking library
- **Kotest** - Assertion library
- **Clock** - Inject for time-dependent code

## Domain Test Template

```kotlin
package com.munserv.{{feature}}.domain

import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeInstanceOf
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class {{Name}}Test {
    // Test fixtures
    private val testId = {{Name}}Id(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))
    private val testCreatedAt = Instant.parse("2025-01-01T10:00:00Z")

    /**
     * Factory for creating test instances with sensible defaults.
     */
    private fun createTest{{Name}}(
        id: {{Name}}Id = testId,
        createdAt: Instant = testCreatedAt,
        updatedAt: Instant = testCreatedAt,
    ) = {{Name}}(
        id = id,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )

    @Test
    fun `should create {{name}} with all properties`() {
        // Arrange & Act
        val entity = createTest{{Name}}()

        // Assert
        entity.id shouldBe testId
        entity.createdAt shouldBe testCreatedAt
    }

    @Nested
    inner class ImmutableUpdates {
        @Test
        fun `withUpdatedAt should return new instance with updated timestamp`() {
            // Arrange
            val original = createTest{{Name}}()
            val newTimestamp = Instant.parse("2025-01-02T15:30:00Z")

            // Act
            val updated = original.withUpdatedAt(newTimestamp)

            // Assert
            updated.updatedAt shouldBe newTimestamp
            original.updatedAt shouldBe testCreatedAt
            updated shouldNotBe original
        }
    }

    @Nested
    inner class Equality {
        @Test
        fun `entities with same properties should be equal`() {
            val entity1 = createTest{{Name}}()
            val entity2 = createTest{{Name}}()
            entity1 shouldBe entity2
        }

        @Test
        fun `entities with different ids should not be equal`() {
            val entity1 = createTest{{Name}}()
            val entity2 = createTest{{Name}}(id = {{Name}}Id(UUID.randomUUID()))
            entity1 shouldNotBe entity2
        }
    }
}
```

## Service Test Template

```kotlin
package com.munserv.{{feature}}.service

import com.munserv.{{feature}}.domain.{{Name}}
import com.munserv.{{feature}}.domain.{{Name}}Id
import com.munserv.{{feature}}.repository.{{Name}}Repository
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.util.UUID

class {{Name}}ServiceTest {
    // Mocks
    private val repository: {{Name}}Repository = mockk()
    private val fixedInstant = Instant.parse("2025-01-15T10:00:00Z")
    private val clock: Clock = Clock.fixed(fixedInstant, ZoneId.UTC)

    // System under test
    private lateinit var service: {{Name}}Service

    // Test data
    private val testId = {{Name}}Id(UUID.fromString("550e8400-e29b-41d4-a716-446655440001"))

    private fun createTest{{Name}}() = {{Name}}(
        id = testId,
        createdAt = fixedInstant,
        updatedAt = fixedInstant,
    )

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        service = {{Name}}Service(repository, clock)
    }

    @Nested
    inner class FindById {
        @Test
        fun `should return Success when {{name}} exists`() {
            // Arrange
            val entity = createTest{{Name}}()
            every { repository.findById(testId) } returns entity

            // Act
            val result = service.findById(testId)

            // Assert
            result.shouldBeInstanceOf<{{Name}}Result.Success>()
            (result as {{Name}}Result.Success).{{nameLower}} shouldBe entity
            verify(exactly = 1) { repository.findById(testId) }
        }

        @Test
        fun `should return NotFound when {{name}} does not exist`() {
            // Arrange
            every { repository.findById(testId) } returns null

            // Act
            val result = service.findById(testId)

            // Assert
            result.shouldBeInstanceOf<{{Name}}Result.NotFound>()
            (result as {{Name}}Result.NotFound).id shouldBe testId
        }
    }

    @Nested
    inner class Create {
        @Test
        fun `should create and save {{name}}`() {
            // Arrange
            val command = Create{{Name}}Command()
            val savedEntity = createTest{{Name}}()
            every { repository.save(any()) } returns savedEntity

            // Act
            val result = service.create(command)

            // Assert
            result.shouldBeInstanceOf<{{Name}}Result.Success>()
            verify { repository.save(match { it.createdAt == fixedInstant }) }
        }
    }

    @Nested
    inner class Update {
        @Test
        fun `should return NotFound when {{name}} does not exist`() {
            // Arrange
            every { repository.findByIdForUpdate(testId) } returns null

            // Act
            val result = service.update(testId, Update{{Name}}Command())

            // Assert
            result.shouldBeInstanceOf<{{Name}}Result.NotFound>()
        }

        @Test
        fun `should update and save {{name}}`() {
            // Arrange
            val existing = createTest{{Name}}()
            val updated = existing.withUpdatedAt(fixedInstant)
            every { repository.findByIdForUpdate(testId) } returns existing
            every { repository.save(any()) } returns updated

            // Act
            val result = service.update(testId, Update{{Name}}Command())

            // Assert
            result.shouldBeInstanceOf<{{Name}}Result.Success>()
            verify { repository.save(any()) }
        }
    }
}
```

## Test Patterns

### Arrange-Act-Assert (AAA)

```kotlin
@Test
fun `should do something when condition`() {
    // Arrange
    val input = createTestInput()
    every { mock.method(any()) } returns expected

    // Act
    val result = service.doSomething(input)

    // Assert
    result shouldBe expected
    verify { mock.method(input) }
}
```

### MockK Patterns

```kotlin
// Basic mock
every { repository.findById(any()) } returns entity

// Returns null
every { repository.findById(any()) } returns null

// Capture argument
val slot = slot<{{Name}}>()
every { repository.save(capture(slot)) } answers { slot.captured }

// Verify call count
verify(exactly = 1) { repository.findById(testId) }
verify { repository.save(any()) wasNot Called }

// Relaxed mock (returns defaults)
private val repository: {{Name}}Repository = mockk(relaxed = true)
```

### Kotest Assertions

```kotlin
// Equality
result shouldBe expected
result shouldNotBe other

// Type checking
result.shouldBeInstanceOf<{{Name}}Result.Success>()

// Null checking
result.shouldNotBeNull()
result.shouldBeNull()

// Collections
list.shouldContain(element)
list.shouldHaveSize(3)
list.shouldBeEmpty()

// Exceptions
shouldThrow<IllegalArgumentException> { service.doSomething() }
```

## Test Rules

1. **TDD** - Write tests BEFORE implementation for domain/service
2. **AAA Pattern** - Arrange, Act, Assert structure
3. **One Assertion Focus** - Each test should verify one behavior
4. **Descriptive Names** - Use backticks with clear descriptions
5. **Test Fixtures** - Use factory methods for test data
6. **Nested Classes** - Group related tests with `@Nested`
7. **Mock All Dependencies** - Isolate unit under test
8. **Inject Clock** - Use fixed clock for time-dependent tests

## Output

Generate test file matching the `{{type}}`:
- `domain` → Test domain entity behavior, state transitions
- `service` → Test service with mocked repository
- `util` → Test utility functions
