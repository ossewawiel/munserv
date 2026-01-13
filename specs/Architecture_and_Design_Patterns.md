# Architecture & Design Patterns

**Project:** MunServ | **Version:** 1.0 | **Status:** Approved

---

## 1. System Structure

**Pattern:** Modular Monolith (one deployable per pod)

```
POD INSTANCE
├── Spring Boot Application
│   ├── [Feature Modules] ──→ issues, members, sectors, auth, reports
│   └── [Shared Module] ────→ security, config, common utilities
├── PostgreSQL + PostGIS
└── Cloudflare R2 (photos)
```

**Rules:**

- Each pod = one application instance + one database
- Horizontal scaling = deploy more pods, not more services
- Modules communicate via service interfaces, never direct repository access

---

## 2. Backend Architecture (Kotlin/Spring Boot)

### 2.1 Layer Structure

```
┌─────────────────────────────────────────┐
│  CONTROLLER (API Layer)                 │  ← DTOs in, DTOs out
├─────────────────────────────────────────┤
│  SERVICE (Application Layer)            │  ← Orchestration, returns sealed Results
├─────────────────────────────────────────┤
│  DOMAIN (Business Layer)                │  ← Entities, Value Objects, domain logic
├─────────────────────────────────────────┤
│  REPOSITORY (Data Layer)                │  ← Spring Data interfaces
└─────────────────────────────────────────┘
```

### 2.2 Dependency Rules

| Layer      | Can Depend On         | Cannot Depend On            |
| ---------- | --------------------- | --------------------------- |
| Controller | Service, DTOs         | Repository, Domain directly |
| Service    | Domain, Repository    | Controller                  |
| Domain     | Nothing (pure Kotlin) | Spring, JPA annotations     |
| Repository | Domain entities       | Service, Controller         |

### 2.3 Module Structure

```
src/main/kotlin/com/munserv/
├── issues/
│   ├── api/
│   │   ├── IssueController.kt
│   │   ├── IssueRequest.kt
│   │   └── IssueResponse.kt
│   ├── domain/
│   │   ├── Issue.kt
│   │   ├── IssueState.kt
│   │   └── IssueType.kt
│   ├── service/
│   │   ├── IssueService.kt
│   │   └── IssueResult.kt
│   └── repository/
│       ├── IssueRepository.kt
│       └── IssueEntity.kt (JPA)
├── members/
│   └── [same structure]
├── sectors/
│   └── [same structure]
└── shared/
    ├── security/
    ├── config/
    └── types/
```

### 2.4 Kotlin Patterns

**Functional bias - use these idioms:**

```kotlin
// Value Objects (type safety)
@JvmInline value class IssueId(val value: UUID)
@JvmInline value class SectorId(val value: UUID)

// Domain Entity (pure, no annotations)
data class Issue(
    val id: IssueId,
    val sectorId: SectorId,
    val type: IssueType,
    val state: IssueState,
    val location: GeoPoint,
    val heat: Int,
    val reportedAt: Instant
) {
    fun canTransitionTo(newState: IssueState): Boolean =
        state.allowedTransitions.contains(newState)

    fun withState(newState: IssueState): Issue = 
        copy(state = newState)
}

// Sealed Results (not exceptions)
sealed interface IssueResult {
    data class Success(val issue: Issue) : IssueResult
    data class NotFound(val id: IssueId) : IssueResult
    data class InvalidTransition(val from: IssueState, val to: IssueState) : IssueResult
    data class ValidationError(val errors: List<String>) : IssueResult
}

// State as sealed class
sealed class IssueState(val allowedTransitions: Set<IssueState>) {
    object Reported : IssueState(setOf(Confirmed, Rejected))
    object Confirmed : IssueState(setOf(InProgress, Rejected))
    object InProgress : IssueState(setOf(Fixed, Rejected))
    object Fixed : IssueState(setOf(Reopened))
    object Rejected : IssueState(emptySet())
    object Reopened : IssueState(setOf(Confirmed))
}

// Service (orchestration)
class IssueService(
    private val issueRepository: IssueRepository,
    private val sectorService: SectorService // cross-module interface
) {
    fun updateState(id: IssueId, newState: IssueState): IssueResult {
        val issue = issueRepository.findById(id)
            ?: return IssueResult.NotFound(id)

        if (!issue.canTransitionTo(newState))
            return IssueResult.InvalidTransition(issue.state, newState)

        return IssueResult.Success(
            issueRepository.save(issue.withState(newState))
        )
    }
}

// Controller (thin, maps results to HTTP)
@RestController
@RequestMapping("/v1/issues")
class IssueController(private val service: IssueService) {

    @PatchMapping("/{id}/state")
    fun updateState(@PathVariable id: UUID, @RequestBody req: StateChangeRequest): ResponseEntity<*> =
        when (val result = service.updateState(IssueId(id), req.toState())) {
            is IssueResult.Success -> ResponseEntity.ok(result.issue.toResponse())
            is IssueResult.NotFound -> ResponseEntity.notFound().build()
            is IssueResult.InvalidTransition -> ResponseEntity.badRequest().body(result)
            is IssueResult.ValidationError -> ResponseEntity.badRequest().body(result.errors)
        }
}
```

### 2.5 Cross-Module Communication

```kotlin
// Module exposes interface
interface SectorService {
    fun findById(id: SectorId): Sector?
    fun findByLocation(point: GeoPoint): Sector?
}

// Other modules depend on interface, not implementation
class IssueService(
    private val sectorService: SectorService  // injected
)
```

### 2.6 Shared Infrastructure Services

Infrastructure services provide cross-cutting concerns like email, SMS, file storage, and external integrations. They follow a consistent pattern:

```kotlin
// Interface in shared module
interface EmailService {
    fun sendEmail(to: String, subject: String, body: String): EmailResult
    fun sendTemplatedEmail(to: String, template: EmailTemplate, context: Map<String, Any>): EmailResult
}

sealed interface EmailResult {
    object Success : EmailResult
    data class Failed(val reason: String) : EmailResult
    data class InvalidAddress(val email: String) : EmailResult
}

// Implementation in shared module
@Service
class SmtpEmailService(
    private val mailSender: JavaMailSender,
    private val templateEngine: TemplateEngine
) : EmailService {

    override fun sendEmail(to: String, subject: String, body: String): EmailResult {
        return try {
            val message = SimpleMailMessage().apply {
                setTo(to)
                setSubject(subject)
                setText(body)
            }
            mailSender.send(message)
            EmailResult.Success
        } catch (e: MailException) {
            EmailResult.Failed(e.message ?: "Unknown error")
        }
    }

    override fun sendTemplatedEmail(
        to: String,
        template: EmailTemplate,
        context: Map<String, Any>
    ): EmailResult {
        val body = templateEngine.process(template.templateName, Context().apply {
            setVariables(context)
        })
        return sendEmail(to, template.subject, body)
    }
}

// Email templates as sealed class
sealed class EmailTemplate(val templateName: String, val subject: String) {
    object WelcomeMember : EmailTemplate(
        templateName = "welcome-member",
        subject = "Welcome to MunServ - Your Account Details"
    )
    object PasswordReset : EmailTemplate(
        templateName = "password-reset",
        subject = "MunServ - Password Reset Request"
    )
}
```

**Configuration pattern:**

```yaml
# application.yml
spring:
  mail:
    host: ${SMTP_HOST:smtp.gmail.com}
    port: ${SMTP_PORT:587}
    username: ${SMTP_USERNAME}
    password: ${SMTP_PASSWORD}
    properties:
      mail.smtp.auth: true
      mail.smtp.starttls.enable: true

munserv:
  email:
    from: ${EMAIL_FROM:noreply@munserv.app}
    enabled: ${EMAIL_ENABLED:true}
```

**Usage in feature services:**

```kotlin
// Registration service uses EmailService
class RegistrationService(
    private val memberRepository: MemberRepository,
    private val emailService: EmailService,
    private val passwordService: PasswordService
) {
    fun approveMember(memberId: MemberId): RegistrationResult {
        val member = memberRepository.findById(memberId)
            ?: return RegistrationResult.MemberNotFound(memberId)

        val tempPassword = passwordService.generateTemporary()
        val updatedMember = member.copy(
            status = MemberStatus.Active,
            passwordHash = passwordService.hash(tempPassword),
            mustChangePassword = true
        )
        memberRepository.save(updatedMember)

        // Send welcome email
        val emailResult = emailService.sendTemplatedEmail(
            to = member.email.value,
            template = EmailTemplate.WelcomeMember,
            context = mapOf(
                "firstName" to member.firstName,
                "tempPassword" to tempPassword,
                "appDownloadUrl" to "https://munserv.app/download"
            )
        )

        return when (emailResult) {
            is EmailResult.Success -> RegistrationResult.Approved(updatedMember)
            is EmailResult.Failed -> RegistrationResult.EmailFailed(emailResult.reason)
            is EmailResult.InvalidAddress -> RegistrationResult.InvalidEmail(member.email)
        }
    }
}
```

**Infrastructure service rules:**

| Rule | Description |
|------|-------------|
| Interface in shared | Define interface in `shared/` module for testability |
| Sealed results | Return sealed results, never throw exceptions |
| Configuration driven | Use environment variables for all external settings |
| Feature services consume | Feature modules inject and use via interface |
| Never direct access | Controllers never call infrastructure services directly |

---

## 3. Mobile Architecture (Flutter/Dart)

### 3.1 Layer Structure

```
┌─────────────────────────────────────────┐
│  PRESENTATION (UI Layer)                │  ← Widgets, Pages
├─────────────────────────────────────────┤
│  PROVIDERS (State Layer)                │  ← Riverpod providers
├─────────────────────────────────────────┤
│  USE CASES (Application Layer)          │  ← Business operations
├─────────────────────────────────────────┤
│  REPOSITORY (Data Layer)                │  ← API calls, local storage
└─────────────────────────────────────────┘
```

### 3.2 Folder Structure

```
lib/
├── features/
│   ├── issues/
│   │   ├── data/
│   │   │   ├── issue_repository.dart
│   │   │   └── issue_api.dart
│   │   ├── domain/
│   │   │   ├── issue.dart
│   │   │   └── issue_state.dart
│   │   ├── providers/
│   │   │   └── issue_providers.dart
│   │   └── presentation/
│   │       ├── issue_list_page.dart
│   │       └── widgets/
│   └── members/
│       └── [same structure]
├── shared/
│   ├── widgets/
│   ├── providers/
│   └── utils/
└── main.dart
```

### 3.3 Riverpod Patterns

```dart
// Domain model (immutable)
@freezed
class Issue with _$Issue {
  const factory Issue({
    required String id,
    required IssueType type,
    required IssueState state,
    required GeoPoint location,
    required DateTime reportedAt,
  }) = _Issue;
}

// Repository
abstract class IssueRepository {
  Future<Result<List<Issue>>> getIssues();
  Future<Result<Issue>> reportIssue(ReportIssueRequest request);
}

// Providers
@riverpod
Future<List<Issue>> issues(IssuesRef ref) async {
  final repository = ref.watch(issueRepositoryProvider);
  final result = await repository.getIssues();
  return result.getOrThrow();
}

// Usage in widget
class IssueListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(issuesProvider);
    return issuesAsync.when(
      data: (issues) => IssueList(issues: issues),
      loading: () => const LoadingSpinner(),
      error: (e, _) => ErrorDisplay(error: e),
    );
  }
}
```

---

## 4. Web Architecture (React/TypeScript)

### 4.1 Atomic Design Structure

```
src/
├── components/
│   ├── atoms/          ← Button, Input, Icon, Badge, Spinner
│   ├── molecules/      ← SearchBar, FormField, IssueCard, StatBadge
│   ├── organisms/      ← IssueList, MemberTable, SectorMap, Navbar
│   ├── templates/      ← DashboardLayout, AuthLayout, ReportLayout
│   └── pages/          ← DashboardPage, IssuesPage, MembersPage
├── features/
│   ├── issues/
│   │   ├── api.ts
│   │   ├── hooks.ts
│   │   └── types.ts
│   └── members/
│       └── [same structure]
├── shared/
│   ├── hooks/
│   ├── utils/
│   └── types/
└── App.tsx
```

### 4.2 Component Rules

| Level     | Contains                           | Examples                         |
| --------- | ---------------------------------- | -------------------------------- |
| Atoms     | Single HTML element + styling      | `<Button>`, `<Input>`, `<Badge>` |
| Molecules | 2-3 atoms combined                 | `<SearchBar>`, `<IssueCard>`     |
| Organisms | Multiple molecules, business logic | `<IssueList>`, `<HeatMap>`       |
| Templates | Page layouts, no data fetching     | `<DashboardLayout>`              |
| Pages     | Data fetching, compose organisms   | `<IssuesPage>`                   |

### 4.3 State & Data Patterns

```typescript
// Types
interface Issue {
  id: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  heat: number;
}

// API hook (React Query)
function useIssues(sectorId: string) {
  return useQuery({
    queryKey: ['issues', sectorId],
    queryFn: () => issueApi.getBySector(sectorId),
  });
}

// Page component
function IssuesPage() {
  const { sectorId } = useParams();
  const { data: issues, isLoading, error } = useIssues(sectorId);

  if (isLoading) return <LoadingTemplate />;
  if (error) return <ErrorTemplate error={error} />;

  return (
    <DashboardTemplate>
      <IssueList issues={issues} />
    </DashboardTemplate>
  );
}
```

### 4.4 MUI Theming Patterns

The web admin uses MUI v7 with CSS variables for theming. See [Web_Theming_Guide.md](Web_Theming_Guide.md) for complete theming documentation.

**Using the `sx` prop for styling:**

```typescript
// Theme color tokens
<Box sx={{ bgcolor: 'primary.main', color: 'primary.contrastText' }} />

// Responsive values
<Box sx={{ p: { xs: 2, sm: 3, md: 4 } }} />

// Nested selectors
<TableRow
  sx={{
    cursor: 'pointer',
    '&:hover': { bgcolor: 'action.hover' },
  }}
/>
```

**Using CSS variables directly:**

```typescript
// When you need raw color values
<Box sx={{ bgcolor: 'var(--munserv-palette-primary-main)' }} />
```

**Component patterns:**

```typescript
// Atoms use MUI components directly
import MuiButton from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';

export const Button: FC<ButtonProps> = ({ variant, isLoading, ...props }) => (
  <MuiButton
    variant={variant === 'primary' ? 'contained' : 'outlined'}
    startIcon={isLoading ? <CircularProgress size={16} /> : undefined}
    {...props}
  />
);

// Molecules compose atoms
import Box from '@mui/material/Box';
import { Button } from '@/components/atoms/Button';

export const LoginForm: FC<LoginFormProps> = ({ onSubmit }) => (
  <Box component="form" sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
    <Input label="Email" />
    <Button type="submit">Login</Button>
  </Box>
);
```

**Pod theming (per-customer colors):**

```typescript
// Theme context loads pod-specific colors at runtime
const { setPodTheme } = useTheme();

// Load from API or environment
const podConfig = await fetchPodConfig();
setPodTheme({
  podId: 'pod-123',
  colors: {
    primary: '#233D36',    // Forest Green
    secondary: '#D9613F',  // Terracotta
  },
});
```

---

## 5. Quick Reference

### Do This ✅

| Area    | Pattern                                               |
| ------- | ----------------------------------------------------- |
| Kotlin  | Immutable data classes, sealed results, value objects |
| Kotlin  | Domain logic in entities, orchestration in services   |
| Kotlin  | Extension functions for conversions                   |
| Flutter | Riverpod for state, freezed for models                |
| React   | React Query for server state, MUI `sx` prop for styles |
| React   | MUI components (Box, Typography, Button, etc.)        |
| All     | Feature-based folders, co-located tests               |

### Don't Do This ❌

| Area    | Anti-Pattern                                     |
| ------- | ------------------------------------------------ |
| Kotlin  | Throwing exceptions for business errors          |
| Kotlin  | JPA annotations on domain entities               |
| Kotlin  | Services calling other module's repositories     |
| Flutter | setState for complex state                       |
| React   | Prop drilling beyond 2 levels                    |
| React   | Inline styles (use `sx` prop instead)            |
| React   | Direct color values (use theme tokens)           |
| All     | Business logic in controllers/widgets/components |

---

## 6. Error Handling Summary

| Layer      | Kotlin                           | Dart                   | TypeScript              |
| ---------- | -------------------------------- | ---------------------- | ----------------------- |
| Domain     | Sealed `Result` types            | `Result<T>`            | Discriminated unions    |
| API        | `@ControllerAdvice` → HTTP codes | `try/catch` → error UI | React Query error state |
| Validation | Return `ValidationError` result  | Return `Failure`       | Zod + form errors       |

---

*Document optimized for LLM context. Include when generating code for any MunServ component.*
