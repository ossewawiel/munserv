# Backend card - Kotlin 2.3 + Spring Boot 4.1

Read `domain/README.md` first. Load the `backend-patterns` skill for worked examples of everything below.

## Layers
`Controller (api/)` → `Service (service/)` → `Domain (domain/)` ← `Repository (repository/)`. Dependencies point down only; the domain has none. One package per feature under `com.munserv.<feature>/{api,domain,service,repository}`; cross-module access goes through the other module's service interface, never its repository.

## The five patterns
1. **Type-safe ids**: `@JvmInline value class IssueId(val value: UUID)`; never pass raw UUIDs between layers.
2. **Pure domain**: `data class` with behaviour (`canTransitionTo`, `withState`), no JPA or Spring annotations. JPA lives in `repository/*Entity.kt` with `toDomain()` / `fromDomain()`.
3. **Sealed state**: lifecycle as a sealed class with `allowedTransitions`; the domain is the only authority on legal moves.
4. **Sealed result**: services return `sealed interface XResult { Success; NotFound; ValidationError; ... }`, never throw for business outcomes. Controllers `when` over the result and map to HTTP.
5. **DTOs at the edge**: `*Request` with `toCommand()`, `*Response` via `toResponse()` extension; enums serialise as snake_case wire values with `@JsonValue`.

## Spring Boot 4 specifics
- Starters are `spring-boot-starter-webmvc`, `-data-jpa`, `-security`, `-validation`, `-actuator`, `-mail`, `-aspectj`, `-flyway`. Versions come from the BOM; do not pin what the BOM manages.
- Jackson 3: `tools.jackson.databind.ObjectMapper`, `tools.jackson.module.kotlin.jacksonObjectMapper`; annotations stay `com.fasterxml.jackson.annotation.*`. Boot auto-registers the Kotlin module; do not add a custom mapper.
- Spring 7 nullability: `PasswordEncoder.encode` returns `String?`; wrap with `requireNotNull`. Domain classes decide nullability explicitly.
- Hibernate 7 + PostGIS: no dialect property; `GEOGRAPHY(POINT,4326)` columns map to JTS `Point`.
- Test slices: `org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc`, `org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest`, `org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase`.

## Tests
JUnit 6, MockK + SpringMockK, Kotest assertions, Testcontainers 2. Every Spring context test does `@Import(TestContainersConfig::class)`; the container is PostGIS 18 via `@ServiceConnection`, so there is no datasource in `application-test.yml`. Domain and service tests are written first (TDD); controller and repository tests after. Names: `` `should X when Y` ``; Arrange / Act / Assert.

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

### Integration Test Pattern (Testcontainers)
Every Spring context test imports the shared `TestContainersConfig`, which
exposes a PostGIS `PostgreSQLContainer` bean with `@ServiceConnection`. No
`@DynamicPropertySource` and no datasource URL in `application-test.yml`.
```kotlin
@SpringBootTest
@Import(TestContainersConfig::class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class IssueApiContractTest { ... }

@DataJpaTest
@Import(TestContainersConfig::class, JpaIssueRepository::class)
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class IssueRepositoryTest { ... }
```
Boot 4 packages: `org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc`,
`org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest`,
`org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase`.

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
./gradlew ktlintFormat && ./gradlew ktlintCheck   # style (ktlint 1.8)
./gradlew test                                    # 1054 tests, needs Docker
./gradlew build -x test                           # jar
./gradlew bootRun                                 # port 8080; dev DB on 5435
```
Swagger: http://localhost:8080/swagger-ui.html. OpenAPI annotations (`@Tag`, `@Operation`, `@ApiResponses`, `@Schema`) on every public endpoint and DTO.

## Forbidden
`!!` without a preceding check; `var` for state; exceptions for business flow; JPA annotations on domain classes; mutable collections in public APIs; field `@Autowired`; business logic in controllers; direct repository access across modules; a new enum value without the matching migration, web and mobile change and `domain/` update.

## Skills
`/dev-cycle`, `/fix-issue`, `/feature`, `/entity`, `/service`, `/controller`, `/repository`, `/migration`, `/test`, `/integration-test`, `/contract-test`, `/review`, `/ci-fix` in `backend/.claude/commands/`.
