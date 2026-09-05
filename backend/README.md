# MunServ Backend

Kotlin + Spring Boot REST API for the MunServ platform.

## Setup

### Prerequisites

- JDK 21+
- Gradle (wrapper included)
- PostgreSQL 16+ with PostGIS extension

### Installation

```bash
cd backend
./gradlew build
```

### Database Setup

```bash
# Create database
psql -U postgres -c "CREATE DATABASE munserv"
psql -U postgres -d munserv -c "CREATE EXTENSION postgis"

# Configure connection
cp src/main/resources/application-local.yml.example src/main/resources/application-local.yml
# Edit application-local.yml with your database credentials
```

### Running the App

```bash
./gradlew bootRun
# Runs on http://localhost:8080
```

### Running Tests

```bash
./gradlew test                    # All tests
./gradlew test --tests "*IssueServiceTest"  # Specific test
./gradlew test --continuous       # Watch mode
```

## Commands

| Command | Description |
|---------|-------------|
| `./gradlew bootRun` | Start dev server (port 8080) |
| `./gradlew build` | Build project |
| `./gradlew test` | Run all tests |
| `./gradlew check` | Run tests + linting |
| `./gradlew clean` | Clean build artifacts |

## Tech Stack

- **Kotlin 2.x** with JDK 21
- **Spring Boot 4.x** for framework
- **Spring Data JPA** for persistence
- **PostgreSQL + PostGIS** for database
- **JUnit 5** for testing
- **MockK** for mocking

## Project Structure

```
src/main/kotlin/com/munserv/
├── issues/
│   ├── api/              # Controllers, request/response DTOs
│   ├── domain/           # Pure domain entities, value objects
│   ├── service/          # Business logic, Result pattern
│   └── repository/       # JPA entities, Spring Data repositories
├── members/
│   └── [same structure]
├── sectors/
│   └── [same structure]
├── auth/
│   └── [same structure]
└── shared/
    ├── config/           # Spring configuration
    ├── security/         # JWT, authentication
    └── types/            # Shared value objects
```

## Development with Claude Code

### Available Skills

| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | Full TDD workflow: Specify → Test → Code → Refactor → Quality |
| `/entity` | Create JPA entity with domain model |
| `/service` | Create service class with Result pattern |
| `/controller` | Create REST controller with DTOs |
| `/repository` | Create Spring Data repository |
| `/migration` | Create Flyway database migration |
| `/test` | Generate unit test (MockK) |
| `/contract-test` | Generate API contract test |
| `/integration-test` | Generate integration test |
| `/review` | Code review for patterns |
| `/ci-fix` | Debug CI/CD failures |

### TDD Workflow

```
1. SPECIFY    → Define acceptance criteria
2. TEST       → Write failing tests FIRST (Red)
3. CODE       → Implement to pass tests (Green)
4. REFACTOR   → Clean up, fix review issues
5. QUALITY    → Run check, coverage analysis
```

Use `/dev-cycle "your task"` to orchestrate this workflow.

## Architecture

```
Controller (API) → Service (Application) → Domain → Repository (Data)
```

| Layer | Responsibility | Depends On |
|-------|----------------|------------|
| Controller | HTTP mapping, DTOs, validation | Service |
| Service | Orchestration, transactions, Result pattern | Domain, Repository |
| Domain | Business logic, state rules, pure Kotlin | Nothing |
| Repository | Data access, JPA entities | Domain |

**Rule:** Dependencies flow down only. Domain has zero dependencies.

## Key Patterns

### Value Objects (Type-Safe IDs)
```kotlin
@JvmInline value class IssueId(val value: UUID)
@JvmInline value class SectorId(val value: UUID)

fun findById(id: IssueId): Issue?  // Can't accidentally pass SectorId
```

### Sealed Result Pattern
```kotlin
sealed interface IssueResult {
    data class Success(val issue: Issue) : IssueResult
    data class NotFound(val id: IssueId) : IssueResult
    data class InvalidTransition(val from: IssueState, val to: IssueState) : IssueResult
}

// Usage
when (val result = service.updateState(id, newState)) {
    is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
    is IssueResult.NotFound -> ResponseEntity.notFound().build()
    is IssueResult.InvalidTransition -> ResponseEntity.badRequest().body(...)
}
```

### Domain Entity (Pure, No Framework)
```kotlin
data class Issue(
    val id: IssueId,
    val sectorId: SectorId,
    val type: IssueType,
    val state: IssueState,
    val location: GeoPoint,
    val heat: Int
) {
    fun canTransitionTo(newState: IssueState): Boolean =
        state.allowedTransitions.contains(newState)

    fun withState(newState: IssueState): Issue = copy(state = newState)
}
```

### Controller Pattern
```kotlin
@RestController
@RequestMapping("/api/v1/issues")
class IssueController(private val issueService: IssueService) {

    @GetMapping("/{id}")
    fun getById(@PathVariable id: UUID): ResponseEntity<IssueResponse> {
        return when (val result = issueService.findById(IssueId(id))) {
            is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
            is IssueResult.NotFound -> ResponseEntity.notFound().build()
            else -> ResponseEntity.internalServerError().build()
        }
    }
}
```

## Testing

### Unit Tests (Service Layer)
```kotlin
@Test
fun `updateState returns Success when transition is valid`() {
    // Given
    val issue = testIssue(state = IssueState.Reported)
    every { repository.findById(issue.id) } returns issue

    // When
    val result = service.updateState(issue.id, IssueState.Confirmed)

    // Then
    assertThat(result).isInstanceOf(IssueResult.Success::class.java)
}
```

### Contract Tests (API Layer)
```kotlin
@SpringBootTest
@AutoConfigureMockMvc
class IssuesApiContractTest {

    @Test
    fun `GET issues by id returns 200 with issue details`() {
        mockMvc.get("/api/v1/issues/${testIssue.id}")
            .andExpect {
                status { isOk() }
                jsonPath("$.id") { value(testIssue.id.toString()) }
                jsonPath("$.state") { value("reported") }
            }
    }
}
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/issues` | List issues with filters |
| `GET` | `/api/v1/issues/{id}` | Get issue by ID |
| `POST` | `/api/v1/issues` | Create new issue |
| `PATCH` | `/api/v1/issues/{id}/state` | Update issue state |
| `POST` | `/api/v1/auth/login` | Admin login |
| `GET` | `/api/v1/admin/dashboard` | Dashboard stats |

See [API Contract](../specs/contracts/api.md) for full documentation.

## Documentation

- [CLAUDE.md](CLAUDE.md) — Architecture patterns, coding conventions
- [API Contract](../specs/contracts/api.md) — Endpoint specifications
- [Domain Modeling](../specs/archive/Domain_and_Data_Modeling.md) — Entity definitions
- [Testing Strategy](../specs/archive/Testing_Strategy.md) — Test patterns
