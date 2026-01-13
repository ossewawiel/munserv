# API Contract Test Generator

name: "contract-test"
description: "Generate API contract tests with MockMvc"
parameters:
  - name: "controller"
    description: "Controller name (e.g., 'Issue', 'Member')"
    required: true
  - name: "feature"
    description: "Feature module (e.g., 'issues', 'members')"
    required: true

---

You are an expert Kotlin developer writing API contract tests for the MunServ backend.

## Task

Generate API contract tests for `{{controller}}Controller` in the `{{feature}}` module.

## Output Location

`src/test/kotlin/com/munserv/{{feature}}/api/{{controller}}ApiContractTest.kt`

## Test Framework Stack

- **JUnit 5** - Test framework
- **MockMvc** - HTTP testing
- **MockK** - Service mocking
- **SpringMockK** - MockK Spring integration
- **Kotest** - Assertions

## Contract Test Template

```kotlin
package com.munserv.{{feature}}.api

import com.fasterxml.jackson.databind.ObjectMapper
import com.munserv.{{feature}}.domain.{{Name}}
import com.munserv.{{feature}}.domain.{{Name}}Id
import com.munserv.{{feature}}.service.{{Name}}Result
import com.munserv.{{feature}}.service.{{Name}}Service
import com.ninjasquad.springmockk.MockkBean
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import org.springframework.test.web.servlet.put
import org.springframework.test.web.servlet.delete
import java.time.Instant
import java.util.UUID

@WebMvcTest({{Name}}Controller::class)
@ActiveProfiles("test")
class {{Name}}ApiContractTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockkBean
    private lateinit var service: {{Name}}Service

    private val testId = UUID.fromString("550e8400-e29b-41d4-a716-446655440001")
    private val testCreatedAt = Instant.parse("2025-01-01T10:00:00Z")

    private fun createTest{{Name}}() = {{Name}}(
        id = {{Name}}Id(testId),
        createdAt = testCreatedAt,
        updatedAt = testCreatedAt,
    )

    @Nested
    @WithMockUser
    inner class GetById {
        @Test
        fun `GET &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 200 when found`() {
            // Arrange
            val entity = createTest{{Name}}()
            every { service.findById({{Name}}Id(testId)) } returns {{Name}}Result.Success(entity)

            // Act & Assert
            mockMvc.get("/api/v1/{{feature}}/{id}", testId) {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.id") { value(testId.toString()) }
                jsonPath("$.createdAt") { exists() }
            }

            verify { service.findById({{Name}}Id(testId)) }
        }

        @Test
        fun `GET &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 404 when not found`() {
            // Arrange
            every { service.findById({{Name}}Id(testId)) } returns {{Name}}Result.NotFound({{Name}}Id(testId))

            // Act & Assert
            mockMvc.get("/api/v1/{{feature}}/{id}", testId) {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isNotFound() }
            }
        }

        @Test
        fun `GET &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 401 without auth`() {
            mockMvc.get("/api/v1/{{feature}}/{id}", testId) {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isUnauthorized() }
            }
        }
    }

    @Nested
    @WithMockUser
    inner class List {
        @Test
        fun `GET &#x2F;api&#x2F;v1&#x2F;{{feature}} should return 200 with list`() {
            // Arrange
            val entities = listOf(createTest{{Name}}())
            every { service.findAll() } returns entities

            // Act & Assert
            mockMvc.get("/api/v1/{{feature}}") {
                accept = MediaType.APPLICATION_JSON
            }.andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$") { isArray() }
                jsonPath("$.length()") { value(1) }
                jsonPath("$[0].id") { value(testId.toString()) }
            }
        }
    }

    @Nested
    @WithMockUser
    inner class Create {
        @Test
        fun `POST &#x2F;api&#x2F;v1&#x2F;{{feature}} should return 201 when valid`() {
            // Arrange
            val entity = createTest{{Name}}()
            val request = Create{{Name}}Request(name = "Test")
            every { service.create(any()) } returns {{Name}}Result.Success(entity)

            // Act & Assert
            mockMvc.post("/api/v1/{{feature}}") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isCreated() }
                jsonPath("$.id") { value(testId.toString()) }
            }
        }

        @Test
        fun `POST &#x2F;api&#x2F;v1&#x2F;{{feature}} should return 400 when invalid`() {
            // Arrange - empty request triggers validation
            val request = mapOf<String, Any>()

            // Act & Assert
            mockMvc.post("/api/v1/{{feature}}") {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isBadRequest() }
            }
        }
    }

    @Nested
    @WithMockUser
    inner class Update {
        @Test
        fun `PUT &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 200 when found`() {
            // Arrange
            val entity = createTest{{Name}}()
            val request = Update{{Name}}Request(name = "Updated")
            every { service.update({{Name}}Id(testId), any()) } returns {{Name}}Result.Success(entity)

            // Act & Assert
            mockMvc.put("/api/v1/{{feature}}/{id}", testId) {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isOk() }
                jsonPath("$.id") { value(testId.toString()) }
            }
        }

        @Test
        fun `PUT &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 404 when not found`() {
            // Arrange
            val request = Update{{Name}}Request(name = "Updated")
            every { service.update({{Name}}Id(testId), any()) } returns {{Name}}Result.NotFound({{Name}}Id(testId))

            // Act & Assert
            mockMvc.put("/api/v1/{{feature}}/{id}", testId) {
                contentType = MediaType.APPLICATION_JSON
                content = objectMapper.writeValueAsString(request)
            }.andExpect {
                status { isNotFound() }
            }
        }
    }

    @Nested
    @WithMockUser
    inner class Delete {
        @Test
        fun `DELETE &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 204 when found`() {
            // Arrange
            val entity = createTest{{Name}}()
            every { service.delete({{Name}}Id(testId)) } returns {{Name}}Result.Success(entity)

            // Act & Assert
            mockMvc.delete("/api/v1/{{feature}}/{id}", testId)
                .andExpect {
                    status { isNoContent() }
                }
        }

        @Test
        fun `DELETE &#x2F;api&#x2F;v1&#x2F;{{feature}}&#x2F;{id} should return 404 when not found`() {
            // Arrange
            every { service.delete({{Name}}Id(testId)) } returns {{Name}}Result.NotFound({{Name}}Id(testId))

            // Act & Assert
            mockMvc.delete("/api/v1/{{feature}}/{id}", testId)
                .andExpect {
                    status { isNotFound() }
                }
        }
    }
}
```

## Contract Test Annotations

| Annotation | Purpose |
|------------|---------|
| `@WebMvcTest(Controller::class)` | Test only web layer |
| `@MockkBean` | Mock service with MockK |
| `@WithMockUser` | Simulate authenticated user |
| `@ActiveProfiles("test")` | Use test profile |

## MockMvc DSL Patterns

### GET Request

```kotlin
mockMvc.get("/api/v1/resource/{id}", id) {
    accept = MediaType.APPLICATION_JSON
    header("Authorization", "Bearer token")
}.andExpect {
    status { isOk() }
    jsonPath("$.field") { value("expected") }
}
```

### POST Request

```kotlin
mockMvc.post("/api/v1/resource") {
    contentType = MediaType.APPLICATION_JSON
    content = objectMapper.writeValueAsString(request)
}.andExpect {
    status { isCreated() }
}
```

### JSON Path Assertions

```kotlin
jsonPath("$.id") { value("uuid-string") }
jsonPath("$.items") { isArray() }
jsonPath("$.items.length()") { value(3) }
jsonPath("$.nested.field") { exists() }
jsonPath("$.optional") { doesNotExist() }
```

## Security Test Patterns

```kotlin
// Without auth - expect 401
@Test
fun `should return 401 without auth`() {
    mockMvc.get("/api/v1/resource")
        .andExpect { status { isUnauthorized() } }
}

// With mock user - expect success
@Test
@WithMockUser
fun `should return 200 with auth`() {
    // ...
}

// With specific roles
@Test
@WithMockUser(roles = ["ADMIN"])
fun `should return 200 for admin`() {
    // ...
}
```

## API Contract Rules

1. **Test All Endpoints** - Every controller endpoint needs tests
2. **Test All Status Codes** - 200, 201, 204, 400, 401, 403, 404
3. **Mock Services** - Use `@MockkBean` to isolate controller
4. **Verify Security** - Test with and without authentication
5. **Match Mobile/Web Contract** - Response shape must match frontend expectations
6. **JSON Path Assertions** - Verify response structure

## Output

Generate contract tests for all endpoints in the controller:
- GET list
- GET by ID
- POST create
- PUT update
- DELETE
