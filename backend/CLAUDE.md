# Backend Context - Kotlin + Spring Boot

## Related Specs
- **DevOps Strategy** (`/specs/DevOps_Strategy.md`): Git workflow, commit format, CI/CD
- **Testing Strategy** (`/specs/Testing_Strategy.md`): Test patterns, coverage targets

## Layer Architecture

```
Controller (API) → Service (Application) → Domain → Repository (Data)
```

| Layer | Responsibility | Depends On |
|-------|----------------|------------|
| Controller | HTTP mapping, DTOs, validation | Service |
| Service | Orchestration, transactions, returns Result | Domain, Repository |
| Domain | Business logic, state rules, pure Kotlin | Nothing |
| Repository | Data access, JPA entities | Domain |

**Rule:** Dependencies flow down only. Domain has zero dependencies.

## Module Structure

```
src/main/kotlin/com/munserv/
├── issues/
│   ├── api/
│   │   ├── IssueController.kt
│   │   ├── IssueRequest.kt
│   │   └── IssueResponse.kt
│   ├── domain/
│   │   ├── Issue.kt           ← Pure data class
│   │   ├── IssueState.kt      ← Sealed class
│   │   └── IssueType.kt       ← Enum
│   ├── service/
│   │   ├── IssueService.kt
│   │   └── IssueResult.kt     ← Sealed interface
│   └── repository/
│       ├── IssueRepository.kt ← Spring Data interface
│       └── IssueEntity.kt     ← JPA entity
├── members/
│   └── [same structure]
├── sectors/
│   └── [same structure]
└── shared/
    ├── config/
    ├── security/
    └── types/
        ├── GeoPoint.kt
        └── ValueObjects.kt
```

## Value Objects (Type-Safe IDs)

```kotlin
// Always wrap IDs - prevents mixing issue_id with sector_id
@JvmInline value class IssueId(val value: UUID)
@JvmInline value class SectorId(val value: UUID)
@JvmInline value class MemberId(val value: UUID)

// Usage
fun findById(id: IssueId): Issue?  // Can't accidentally pass SectorId
```

## Domain Entity Pattern

```kotlin
// Domain entity - PURE, no JPA annotations, no framework dependencies
data class Issue(
    val id: IssueId,
    val sectorId: SectorId,
    val reporterId: MemberId,
    val type: IssueType,
    val state: IssueState,
    val location: GeoPoint,
    val heat: Int,
    val reportedAt: Instant
) {
    // Business logic lives HERE
    fun canTransitionTo(newState: IssueState): Boolean =
        state.allowedTransitions.contains(newState)

    // Immutable updates via copy
    fun withState(newState: IssueState): Issue = copy(state = newState)
    fun withHeat(newHeat: Int): Issue = copy(heat = newHeat)
}
```

## Sealed State Pattern

```kotlin
sealed class IssueState(val allowedTransitions: Set<IssueState>) {
    object Reported : IssueState(setOf(Confirmed, Rejected))
    object Confirmed : IssueState(setOf(InProgress, Rejected))
    object InProgress : IssueState(setOf(Fixed, Rejected))
    object Fixed : IssueState(setOf(Reopened))
    object Rejected : IssueState(emptySet())
    object Reopened : IssueState(setOf(Confirmed))
    
    companion object {
        fun fromString(value: String): IssueState = when (value.lowercase()) {
            "reported" -> Reported
            "confirmed" -> Confirmed
            "in_progress" -> InProgress
            "fixed" -> Fixed
            "rejected" -> Rejected
            "reopened" -> Reopened
            else -> throw IllegalArgumentException("Unknown state: $value")
        }
    }
}
```

## Sealed Result Pattern

```kotlin
// Return results, not exceptions
sealed interface IssueResult {
    data class Success(val issue: Issue) : IssueResult
    data class NotFound(val id: IssueId) : IssueResult
    data class InvalidTransition(val from: IssueState, val to: IssueState) : IssueResult
    data class ValidationError(val errors: List<String>) : IssueResult
    data class Unauthorized(val reason: String) : IssueResult
}
```

## Service Pattern

```kotlin
@Service
class IssueService(
    private val repository: IssueRepository,
    private val sectorService: SectorService  // Cross-module via interface
) {
    fun updateState(id: IssueId, newState: IssueState, actor: MemberId): IssueResult {
        // 1. Fetch
        val issue = repository.findById(id)
            ?: return IssueResult.NotFound(id)
        
        // 2. Validate (domain logic)
        if (!issue.canTransitionTo(newState))
            return IssueResult.InvalidTransition(issue.state, newState)
        
        // 3. Apply & persist
        val updated = issue.withState(newState)
        return IssueResult.Success(repository.save(updated))
    }
}
```

## Controller Pattern

```kotlin
@RestController
@RequestMapping("/v1/issues")
class IssueController(private val service: IssueService) {

    @GetMapping("/{id}")
    fun getById(@PathVariable id: UUID): ResponseEntity<IssueResponse> =
        when (val result = service.findById(IssueId(id))) {
            is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
            is IssueResult.NotFound -> ResponseEntity.notFound().build()
            else -> ResponseEntity.internalServerError().build()
        }

    @PatchMapping("/{id}/state")
    fun updateState(
        @PathVariable id: UUID,
        @RequestBody request: StateChangeRequest,
        @AuthenticationPrincipal actor: MemberId
    ): ResponseEntity<*> =
        when (val result = service.updateState(IssueId(id), request.toState(), actor)) {
            is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
            is IssueResult.NotFound -> ResponseEntity.notFound().build()
            is IssueResult.InvalidTransition -> ResponseEntity.badRequest().body(result)
            is IssueResult.ValidationError -> ResponseEntity.badRequest().body(result.errors)
            is IssueResult.Unauthorized -> ResponseEntity.status(403).body(result.reason)
        }
}
```

## JPA Entity (Repository Layer Only)

```kotlin
@Entity
@Table(name = "issues")
class IssueEntity(
    @Id
    val id: UUID,
    
    @Column(name = "sector_id", nullable = false)
    val sectorId: UUID,
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val type: IssueTypeEnum,
    
    @Column(nullable = false)
    val state: String,
    
    @Column(columnDefinition = "geography(Point,4326)")
    val location: Point,
    
    @Column(nullable = false)
    val heat: Int,
    
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant
) {
    // Conversion to domain
    fun toDomain(): Issue = Issue(
        id = IssueId(id),
        sectorId = SectorId(sectorId),
        // ... map all fields
    )
    
    companion object {
        fun fromDomain(issue: Issue): IssueEntity = IssueEntity(
            id = issue.id.value,
            // ... map all fields
        )
    }
}
```

## Repository Pattern

```kotlin
interface IssueRepository {
    fun findById(id: IssueId): Issue?
    fun save(issue: Issue): Issue
    fun findBySectorId(sectorId: SectorId): List<Issue>
    fun findWithinRadius(point: GeoPoint, radiusMeters: Double): List<Issue>
}

@Repository
class JpaIssueRepository(
    private val jpa: IssueJpaRepository
) : IssueRepository {
    
    override fun findById(id: IssueId): Issue? =
        jpa.findByIdOrNull(id.value)?.toDomain()
    
    override fun save(issue: Issue): Issue =
        jpa.save(IssueEntity.fromDomain(issue)).toDomain()
}

interface IssueJpaRepository : JpaRepository<IssueEntity, UUID> {
    @Query("SELECT i FROM IssueEntity i WHERE i.sectorId = :sectorId")
    fun findBySectorId(sectorId: UUID): List<IssueEntity>
}
```

## DTO Patterns

```kotlin
// Request - what client sends
data class CreateIssueRequest(
    val type: String,
    val latitude: Double,
    val longitude: Double,
    val description: String?
) {
    fun toCommand() = CreateIssueCommand(
        type = IssueType.fromString(type),
        location = GeoPoint(latitude, longitude),
        description = description
    )
}

// Response - what client receives
data class IssueResponse(
    val id: String,
    val type: String,
    val state: String,
    val location: LocationResponse,
    val heat: Int,
    val reportedAt: String
)

// Extension for conversion
fun Issue.toResponse() = IssueResponse(
    id = id.value.toString(),
    type = type.name,
    state = state.name,
    location = LocationResponse(location.lat, location.lng),
    heat = heat,
    reportedAt = reportedAt.toString()
)
```

## Null Handling

```kotlin
// ✅ Early return with elvis
val issue = repository.findById(id) ?: return IssueResult.NotFound(id)

// ✅ Safe call with let
user?.let { sendNotification(it) }

// ✅ Elvis for defaults
val name = user?.name ?: "Unknown"

// ❌ Never force unwrap
val name = user!!.name
```

## Cross-Module Communication

```kotlin
// Module exposes interface in its package
interface SectorService {
    fun findById(id: SectorId): Sector?
    fun findByLocation(point: GeoPoint): Sector?
}

// Other modules depend on interface only
class IssueService(
    private val sectorService: SectorService  // Injected
)

// ❌ Never access another module's repository directly
```

## OpenAPI/Swagger Documentation

**URLs:**
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8080/v3/api-docs`

**Configuration:**
- `shared/config/OpenApiConfig.kt` - Global OpenAPI settings
- `application.yml` - SpringDoc configuration

### Controller-Level Annotations

```kotlin
@RestController
@RequestMapping("/api/v1/issues")
@Tag(name = "Issues", description = "Issue management endpoints")
@SecurityRequirement(name = "bearerAuth")  // JWT required
class IssueController(...)
```

### Method-Level Annotations

```kotlin
@Operation(
    summary = "List issues",
    description = "Retrieve paginated issues with filtering"
)
@ApiResponses(value = [
    ApiResponse(responseCode = "200", description = "Success"),
    ApiResponse(responseCode = "401", description = "Unauthorized"),
    ApiResponse(responseCode = "404", description = "Not found")
])
@GetMapping
fun listIssues(
    @Parameter(description = "Filter by sector UUID")
    @RequestParam(required = false) sectorId: String?
): ResponseEntity<PaginatedIssuesResponse>
```

### DTO Schema Annotations

```kotlin
data class CreateIssueRequest(
    @field:Schema(
        description = "Type of issue",
        example = "pothole",
        allowableValues = ["pothole", "water_leak", "other"]
    )
    val type: String,

    @field:Schema(description = "GPS latitude", example = "-26.1350")
    val latitude: Double
)
```

### Annotation Quick Reference

| Annotation | Purpose | Location |
|------------|---------|----------|
| `@Tag` | Group endpoints | Controller class |
| `@Operation` | Endpoint description | Method |
| `@ApiResponses` | Response codes | Method |
| `@Parameter` | Path/query param | Parameter |
| `@Schema` | Data type docs | DTO field |
| `@SecurityRequirement` | Auth required | Class/method |
| `@Hidden` | Exclude from docs | Any |

## Forbidden
- `!!` (force unwrap) without preceding null check
- `var` for state (use `val` + `copy()`)
- Throwing exceptions for business logic flow
- JPA annotations on domain classes
- Mutable collections in public APIs
- `@Autowired` on fields (use constructor injection)
- Business logic in controllers
- Direct repository access across modules

## Testing (JUnit 5 + MockK + Kotest)

### Test Framework Stack
- **JUnit 5** - Test framework
- **MockK** - Mocking library for Kotlin
- **Kotest** - Assertion library
- **TestContainers** - PostgreSQL + PostGIS for integration tests
- **SpringMockK** - MockK integration with Spring

### Unit Test Pattern
```kotlin
class IssueServiceTest {
    private val repository: IssueRepository = mockk()
    private val clock: Clock = Clock.fixed(fixedInstant, ZoneId.UTC)
    private lateinit var service: IssueService

    @BeforeEach
    fun setUp() {
        clearAllMocks()
        service = IssueService(repository, clock)
    }

    @Test
    fun `should return Success when issue exists`() {
        // Arrange
        val issue = createTestIssue()
        every { repository.findById(testId) } returns issue

        // Act
        val result = service.findById(testId)

        // Assert
        result.shouldBeInstanceOf<IssueResult.Success>()
        verify { repository.findById(testId) }
    }
}
```

### Integration Test Pattern (TestContainers)
```kotlin
@DataJpaTest
@Testcontainers
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class IssueRepositoryTest {
    companion object {
        @Container
        val postgres = PostgreSQLContainer(
            DockerImageName.parse("postgis/postgis:15-3.3-alpine")
        )

        @JvmStatic
        @DynamicPropertySource
        fun configureProperties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url") { postgres.jdbcUrl }
        }
    }
}
```

### API Contract Test Pattern
```kotlin
@WebMvcTest(IssueController::class)
@ActiveProfiles("test")
class IssueApiContractTest {
    @Autowired private lateinit var mockMvc: MockMvc
    @MockkBean private lateinit var service: IssueService

    @Test
    @WithMockUser
    fun `GET /api/v1/issues/{id} should return 200 when found`() {
        every { service.findById(any()) } returns IssueResult.Success(issue)

        mockMvc.get("/api/v1/issues/{id}", testId)
            .andExpect { status { isOk() } }
    }
}
```

### Test Commands
```bash
./gradlew test                    # Run all tests
./gradlew test --tests "*.IssueServiceTest"  # Run specific test
./gradlew test --info             # Verbose output
./gradlew jacocoTestReport        # Generate coverage
```

### Kotest Assertions
```kotlin
result shouldBe expected
result shouldNotBe other
result.shouldBeInstanceOf<Type>()
result.shouldNotBeNull()
list.shouldContain(element)
list.shouldHaveSize(3)
shouldThrow<Exception> { code() }
```

### MockK Patterns
```kotlin
every { mock.method(any()) } returns value
every { mock.method(any()) } returns null
verify { mock.method(any()) }
verify(exactly = 1) { mock.method(testId) }
val slot = slot<Issue>()
every { repo.save(capture(slot)) } answers { slot.captured }
```

## Available Skills

Skills are located in `.claude/commands/`. Use `/skill-name` to invoke.

### Code Generation
| Skill | Purpose |
|-------|---------|
| `/entity` | Generate domain entity, value object, or state machine |
| `/feature` | Scaffold complete feature module |
| `/service` | Create service with sealed Result pattern |
| `/controller` | Generate REST controller with DTOs |
| `/repository` | Create JPA repository with entity mapping |
| `/migration` | Generate Flyway SQL migration |

### Quality & Testing
| Skill | Purpose |
|-------|---------|
| `/test` | Generate unit test (MockK + Kotest) |
| `/integration-test` | Generate integration test (TestContainers) |
| `/contract-test` | Generate API contract test (MockMvc) |
| `/review` | Code review for Kotlin/Spring patterns |
| `/ci-fix` | Debug CI/CD failures |

### Workflow
| Skill | Purpose |
|-------|---------|
| `/dev-cycle` | Full TDD workflow: Specify → Test → Code → Refactor → Quality Gate |

## TDD Development Cycle

When adding functionality, follow this workflow:

```
1. SPECIFY    → Define acceptance criteria
2. TEST       → Write failing tests FIRST (Red) - STRICT for domain/service
3. CODE       → Implement to pass tests (Green)
4. REFACTOR   → Clean up, fix review issues
5. QUALITY    → Run ktlint, tests
6. INTEGRATION→ Add contract + integration tests
7. PRE-COMMIT → Full build verification
```

Use `/dev-cycle "your task description"` to orchestrate this workflow.

## Build Commands (WSL2)
```bash
./gradlew build          # Full build
./gradlew test           # Run tests
./gradlew bootRun        # Start dev server (port 8080)
./gradlew ktlintCheck    # Lint check
./gradlew ktlintFormat   # Auto-format
./gradlew jacocoTestReport  # Coverage report
```
