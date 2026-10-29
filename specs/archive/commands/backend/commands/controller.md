# REST Controller Generator

name: "controller"
description: "Generate REST controller with DTOs and OpenAPI annotations"
parameters:
  - name: "name"
    description: "Controller name (e.g., 'Issue', 'Member')"
    required: true
  - name: "feature"
    description: "Feature module (e.g., 'issues', 'members')"
    required: true
  - name: "endpoints"
    description: "Comma-separated endpoints (e.g., 'list,getById,create,update,delete')"
    required: true

---

You are an expert Kotlin developer generating REST controller code for the MunServ backend.

## Task

Generate a REST controller for `{{name}}` in the `{{feature}}` module with endpoints: `{{endpoints}}`.

## Output Files

1. `src/main/kotlin/com/munserv/{{feature}}/api/{{name}}Controller.kt`
2. `src/main/kotlin/com/munserv/{{feature}}/api/{{name}}Request.kt`
3. `src/main/kotlin/com/munserv/{{feature}}/api/{{name}}Response.kt`

## Controller Template

```kotlin
package com.munserv.{{feature}}.api

import com.munserv.{{feature}}.domain.{{name}}Id
import com.munserv.{{feature}}.service.{{name}}Result
import com.munserv.{{feature}}.service.{{name}}Service
import com.munserv.{{feature}}.service.Create{{name}}Command
import com.munserv.{{feature}}.service.Update{{name}}Command
import com.munserv.shared.api.ErrorResponse
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.security.SecurityRequirement
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping("/api/v1/{{feature}}")
@Tag(name = "{{name}}s", description = "{{name}} management endpoints")
@SecurityRequirement(name = "bearerAuth")
class {{name}}Controller(
    private val service: {{name}}Service,
) {
    @GetMapping
    @Operation(summary = "List all {{name}}s")
    @ApiResponses(
        ApiResponse(responseCode = "200", description = "Success"),
        ApiResponse(responseCode = "401", description = "Unauthorized"),
    )
    fun list(): ResponseEntity<List<{{name}}Response>> =
        ResponseEntity.ok(service.findAll().map { it.toResponse() })

    @GetMapping("/{id}")
    @Operation(summary = "Get {{name}} by ID")
    @ApiResponses(
        ApiResponse(responseCode = "200", description = "Success"),
        ApiResponse(responseCode = "404", description = "Not found"),
        ApiResponse(responseCode = "401", description = "Unauthorized"),
    )
    fun getById(
        @Parameter(description = "{{name}} UUID")
        @PathVariable id: UUID,
    ): ResponseEntity<{{name}}Response> =
        when (val result = service.findById({{name}}Id(id))) {
            is {{name}}Result.Success -> ResponseEntity.ok(result.{{nameLower}}.toResponse())
            is {{name}}Result.NotFound -> ResponseEntity.notFound().build()
            else -> ResponseEntity.internalServerError().build()
        }

    @PostMapping
    @Operation(summary = "Create new {{name}}")
    @ApiResponses(
        ApiResponse(responseCode = "201", description = "Created"),
        ApiResponse(responseCode = "400", description = "Validation error"),
        ApiResponse(responseCode = "401", description = "Unauthorized"),
    )
    fun create(
        @Valid @RequestBody request: Create{{name}}Request,
    ): ResponseEntity<*> =
        when (val result = service.create(request.toCommand())) {
            is {{name}}Result.Success ->
                ResponseEntity.status(HttpStatus.CREATED).body(result.{{nameLower}}.toResponse())
            is {{name}}Result.ValidationError ->
                ResponseEntity.badRequest().body(ErrorResponse("VALIDATION_ERROR", result.errors.joinToString(", ")))
            else -> ResponseEntity.internalServerError().build()
        }

    @PutMapping("/{id}")
    @Operation(summary = "Update {{name}}")
    @ApiResponses(
        ApiResponse(responseCode = "200", description = "Success"),
        ApiResponse(responseCode = "404", description = "Not found"),
        ApiResponse(responseCode = "400", description = "Validation error"),
        ApiResponse(responseCode = "401", description = "Unauthorized"),
    )
    fun update(
        @Parameter(description = "{{name}} UUID")
        @PathVariable id: UUID,
        @Valid @RequestBody request: Update{{name}}Request,
    ): ResponseEntity<*> =
        when (val result = service.update({{name}}Id(id), request.toCommand())) {
            is {{name}}Result.Success -> ResponseEntity.ok(result.{{nameLower}}.toResponse())
            is {{name}}Result.NotFound -> ResponseEntity.notFound().build()
            is {{name}}Result.ValidationError ->
                ResponseEntity.badRequest().body(ErrorResponse("VALIDATION_ERROR", result.errors.joinToString(", ")))
            else -> ResponseEntity.internalServerError().build()
        }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete {{name}}")
    @ApiResponses(
        ApiResponse(responseCode = "204", description = "Deleted"),
        ApiResponse(responseCode = "404", description = "Not found"),
        ApiResponse(responseCode = "401", description = "Unauthorized"),
    )
    fun delete(
        @Parameter(description = "{{name}} UUID")
        @PathVariable id: UUID,
    ): ResponseEntity<Void> =
        when (service.delete({{name}}Id(id))) {
            is {{name}}Result.Success -> ResponseEntity.noContent().build()
            is {{name}}Result.NotFound -> ResponseEntity.notFound().build()
            else -> ResponseEntity.internalServerError().build()
        }
}
```

## Request DTOs Template

```kotlin
package com.munserv.{{feature}}.api

import com.munserv.{{feature}}.service.Create{{name}}Command
import com.munserv.{{feature}}.service.Update{{name}}Command
import io.swagger.v3.oas.annotations.media.Schema
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class Create{{name}}Request(
    @field:Schema(description = "Name", example = "Example")
    @field:NotBlank(message = "Name is required")
    @field:Size(max = 255, message = "Name must be less than 255 characters")
    val name: String,
) {
    fun toCommand() = Create{{name}}Command(
        name = name,
    )
}

data class Update{{name}}Request(
    @field:Schema(description = "Name", example = "Updated Example")
    @field:Size(max = 255, message = "Name must be less than 255 characters")
    val name: String?,
) {
    fun toCommand() = Update{{name}}Command(
        name = name,
    )
}
```

## Response DTO Template

```kotlin
package com.munserv.{{feature}}.api

import com.munserv.{{feature}}.domain.{{name}}
import io.swagger.v3.oas.annotations.media.Schema

data class {{name}}Response(
    @field:Schema(description = "Unique identifier", example = "550e8400-e29b-41d4-a716-446655440000")
    val id: String,

    @field:Schema(description = "Creation timestamp", example = "2025-01-01T10:00:00Z")
    val createdAt: String,

    @field:Schema(description = "Last update timestamp", example = "2025-01-01T10:00:00Z")
    val updatedAt: String,
)

/**
 * Extension function to convert domain entity to response DTO.
 */
fun {{name}}.toResponse() = {{name}}Response(
    id = id.value.toString(),
    createdAt = createdAt.toString(),
    updatedAt = updatedAt.toString(),
)
```

## Controller Rules

1. **Constructor Injection** - Service injected via constructor
2. **OpenAPI Annotations** - `@Tag`, `@Operation`, `@ApiResponses` on all endpoints
3. **Validation** - Use `@Valid` on request bodies
4. **ResponseEntity** - Return explicit status codes
5. **Result Matching** - Use `when` to handle all Result cases
6. **Extension Functions** - Use `toResponse()` for DTO conversion
7. **No Domain Entities** - Only DTOs in request/response

## OpenAPI Annotation Reference

| Annotation | Purpose | Location |
|------------|---------|----------|
| `@Tag` | Group endpoints | Class |
| `@Operation` | Endpoint description | Method |
| `@ApiResponses` | Response codes | Method |
| `@Parameter` | Path/query param | Parameter |
| `@Schema` | Field documentation | DTO field |
| `@SecurityRequirement` | Auth required | Class/method |

## Output

Generate controller files based on `{{endpoints}}`:
- `list` → GET / endpoint
- `getById` → GET /{id} endpoint
- `create` → POST / endpoint + Create request
- `update` → PUT /{id} endpoint + Update request
- `delete` → DELETE /{id} endpoint
