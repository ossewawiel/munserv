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

## Commands
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
