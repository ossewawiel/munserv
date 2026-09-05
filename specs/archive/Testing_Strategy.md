# Testing Strategy

**Project:** MunServ | **Version:** 1.0 | **Status:** Approved

*Companion to archive/Architecture_and_Design_Patterns.md and archive/Coding_Standards.md. Include all three as LLM context.*

---

## 1. Philosophy

**Approach:** Pragmatic TDD

| Layer | Requirement | Rationale |
|-------|-------------|-----------|
| Domain | Tests first (strict TDD) | Business rules must be correct |
| Service | Tests first (strict TDD) | Orchestration logic is critical |
| Repository | Tests after | SQL correctness via integration |
| Controller | Tests after | HTTP contracts, less logic |
| UI | Tests optional for MVP | Fast iteration, visual verification |

**Core Principle:** Tests are required before merging for domain and service layers. Other layers encouraged but not blocking.

---

## 2. Test Types by Layer

```
┌─────────────────────────────────────────────────────────────┐
│  E2E Tests        │ Full user flows (Maestro, Playwright)  │
├───────────────────┼─────────────────────────────────────────┤
│  Integration      │ Controller + Repository (real DB)      │
├───────────────────┼─────────────────────────────────────────┤
│  Unit Tests       │ Domain + Service (mocked dependencies) │
└───────────────────┴─────────────────────────────────────────┘
```

| Layer | Test Type | Dependencies | Database |
|-------|-----------|--------------|----------|
| Domain | Unit | None (pure) | None |
| Service | Unit | Mocked | None |
| Repository | Integration | None | TestContainers (PostgreSQL + PostGIS) |
| Controller | Integration | Real or mocked | TestContainers |
| Mobile UI | Widget | Mocked providers | None |
| Web UI | Component | MSW (API mocks) | None |
| Full App | E2E | None | Test environment |

---

## 3. Coverage Targets (MVP)

| Layer | Minimum | Target | Notes |
|-------|---------|--------|-------|
| Domain | 80% | 90% | Business logic is critical |
| Service | 70% | 80% | Orchestration paths |
| Repository | 60% | 70% | Query correctness |
| Controller | 50% | 60% | HTTP contract coverage |
| UI Components | — | 40% | Optional for MVP |

**Enforcement:** CI fails if domain/service coverage drops below minimum.

---

## 4. Frameworks & Tools

### 4.1 Kotlin/Spring Boot

| Purpose | Tool |
|---------|------|
| Test framework | JUnit 5 |
| Mocking | MockK |
| Assertions | Kotest matchers or AssertJ |
| Integration DB | TestContainers (PostgreSQL + PostGIS) |
| API testing | MockMvc / WebTestClient |

### 4.2 Flutter/Dart

| Purpose | Tool |
|---------|------|
| Test framework | flutter_test |
| Mocking | Mocktail |
| Widget testing | WidgetTester |
| Golden tests | golden_toolkit (optional) |
| E2E | Maestro |

### 4.3 React/TypeScript

| Purpose | Tool |
|---------|------|
| Test framework | Vitest |
| Component testing | React Testing Library |
| API mocking | MSW (Mock Service Worker) |
| E2E | Playwright |

---

## 5. Test Organization

### 5.1 File Location

| Platform | Convention | Example |
|----------|------------|---------|
| Kotlin | Mirrored tree | `src/test/kotlin/issues/domain/IssueTest.kt` |
| Flutter | Mirrored tree | `test/features/issues/domain/issue_test.dart` |
| React | Co-located | `src/features/issues/IssueCard.test.tsx` |

### 5.2 Naming Conventions

| Platform | File Pattern | Test Function Pattern |
|----------|--------------|----------------------|
| Kotlin | `{Class}Test.kt` | `` `should do X when Y` `` (backticks) |
| Dart | `{file}_test.dart` | `'should do X when Y'` |
| TypeScript | `{Component}.test.tsx` | `it('should do X when Y')` |

### 5.3 Test Structure (All Platforms)

```
Arrange → Act → Assert  (or Given → When → Then)
```

---

## 6. Kotlin Testing Patterns

### 6.1 Domain Unit Test

```kotlin
class IssueTest {
    @Test
    fun `should allow transition from Reported to Confirmed`() {
        // Arrange
        val issue = Issue(
            id = IssueId(UUID.randomUUID()),
            state = IssueState.Reported,
            // ...
        )
        
        // Act & Assert
        issue.canTransitionTo(IssueState.Confirmed) shouldBe true
        issue.canTransitionTo(IssueState.Fixed) shouldBe false
    }
}
```

### 6.2 Service Unit Test (Mocked)

```kotlin
class IssueServiceTest {
    private val repository = mockk<IssueRepository>()
    private val service = IssueService(repository)

    @Test
    fun `should return NotFound when issue does not exist`() {
        // Arrange
        val id = IssueId(UUID.randomUUID())
        every { repository.findById(id) } returns null

        // Act
        val result = service.updateState(id, IssueState.Confirmed)

        // Assert
        result shouldBe IssueResult.NotFound(id)
    }
}
```

### 6.3 Repository Integration Test (TestContainers)

```kotlin
@DataJpaTest
@Testcontainers
class IssueRepositoryTest {
    companion object {
        @Container
        val postgres = PostgisContainerProvider().newInstance()
    }

    @Autowired
    lateinit var repository: IssueRepository

    @Test
    fun `should find issues within sector boundary`() {
        // Arrange - insert test data
        // Act - call repository method
        // Assert - verify results
    }
}
```

### 6.4 Controller Integration Test

```kotlin
@WebMvcTest(IssueController::class)
class IssueControllerTest {
    @Autowired
    lateinit var mockMvc: MockMvc
    
    @MockkBean
    lateinit var service: IssueService

    @Test
    fun `should return 404 when issue not found`() {
        every { service.findById(any()) } returns IssueResult.NotFound(id)

        mockMvc.get("/v1/issues/{id}", id)
            .andExpect { status { isNotFound() } }
    }
}
```

---

## 7. Flutter Testing Patterns

### 7.1 Domain Unit Test

```dart
void main() {
  group('Issue', () {
    test('should allow transition from reported to confirmed', () {
      // Arrange
      const issue = Issue(id: '1', state: IssueState.reported);
      
      // Act & Assert
      expect(issue.canTransitionTo(IssueState.confirmed), isTrue);
      expect(issue.canTransitionTo(IssueState.fixed), isFalse);
    });
  });
}
```

### 7.2 Repository Test (Mocked API)

```dart
void main() {
  late MockIssueApi mockApi;
  late IssueRepository repository;

  setUp(() {
    mockApi = MockIssueApi();
    repository = IssueRepository(api: mockApi);
  });

  test('should return issues from API', () async {
    // Arrange
    when(() => mockApi.getIssues()).thenAnswer(
      (_) async => [Issue(id: '1', state: IssueState.reported)],
    );

    // Act
    final result = await repository.getIssues();

    // Assert
    expect(result.isSuccess, isTrue);
    expect(result.value, hasLength(1));
  });
}
```

### 7.3 Widget Test

```dart
void main() {
  testWidgets('IssueCard displays issue type', (tester) async {
    // Arrange
    const issue = Issue(id: '1', type: IssueType.pothole);

    // Act
    await tester.pumpWidget(
      MaterialApp(home: IssueCard(issue: issue)),
    );

    // Assert
    expect(find.text('Pothole'), findsOneWidget);
  });
}
```

---

## 8. React Testing Patterns

### 8.1 Component Test

```typescript
import { render, screen } from '@testing-library/react';
import { IssueCard } from './IssueCard';

describe('IssueCard', () => {
  it('should display issue type', () => {
    // Arrange
    const issue = { id: '1', type: 'pothole', state: 'reported' };

    // Act
    render(<IssueCard issue={issue} />);

    // Assert
    expect(screen.getByText('Pothole')).toBeInTheDocument();
  });
});
```

### 8.2 Hook Test with MSW

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useIssues } from './useIssues';
import { server } from '@/mocks/server';
import { http, HttpResponse } from 'msw';

describe('useIssues', () => {
  it('should fetch issues', async () => {
    // Arrange
    server.use(
      http.get('/api/v1/issues', () => 
        HttpResponse.json([{ id: '1', type: 'pothole' }])
      )
    );

    // Act
    const { result } = renderHook(() => useIssues('sector-1'));

    // Assert
    await waitFor(() => expect(result.current.data).toHaveLength(1));
  });
});
```

---

## 9. What NOT to Test

| Skip | Reason |
|------|--------|
| DTOs / Request / Response classes | No logic, covered by integration tests |
| Configuration classes | Tested implicitly via app startup |
| Simple data classes | No behavior |
| Third-party library internals | Not our responsibility |
| UI styling / layout | Use visual review, not automated tests |
| Generated code | Freezed, OpenAPI clients, etc. |

---

## 10. Test Data Management

### 10.1 Factories / Fixtures

```kotlin
// Kotlin - test fixtures
object IssueFixtures {
    fun reported() = Issue(
        id = IssueId(UUID.randomUUID()),
        state = IssueState.Reported,
        type = IssueType.POTHOLE,
        // sensible defaults...
    )
    
    fun confirmed() = reported().copy(state = IssueState.Confirmed)
}
```

```dart
// Dart - test fixtures
class IssueFixtures {
  static Issue reported() => const Issue(
    id: 'test-1',
    state: IssueState.reported,
    type: IssueType.pothole,
  );
}
```

### 10.2 Database Seeding (Integration Tests)

- Use `@Sql` annotations or programmatic setup
- Each test class manages its own data
- Use `@Transactional` for automatic rollback (when possible)

---

## 11. CI Integration

| Stage | Tests Run | Blocks PR |
|-------|-----------|-----------|
| Pre-commit (local) | Unit tests | — |
| PR Build | Unit + Integration | Yes |
| Nightly | E2E | No (alerts only) |
| Pre-release | All | Yes |

**Required Checks:**
- All tests pass
- Coverage thresholds met (domain ≥80%, service ≥70%)
- No skipped tests without `@Disabled("reason")`

---

## 12. Quick Reference

### Do This ✅

| Area | Practice |
|------|----------|
| Domain | 100% test coverage of state transitions and business rules |
| Service | Test all Result branches (Success, NotFound, ValidationError) |
| Mocking | Mock at boundaries (repositories, external APIs) |
| Naming | Descriptive: `should return NotFound when issue does not exist` |
| Data | Use fixtures/factories, not inline object construction |

### Don't Do This ❌

| Area | Anti-Pattern |
|------|--------------|
| Domain | Testing private methods directly |
| Service | Mocking the class under test |
| Repository | Using H2 when PostGIS features are needed |
| General | Testing implementation details instead of behavior |
| General | Multiple assertions testing unrelated things |
| General | Tests that depend on execution order |

---

*Document optimized for LLM context. Include with archive/Architecture_and_Design_Patterns.md and archive/Coding_Standards.md when generating code.*
