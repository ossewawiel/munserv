# CI/CD Failure Debugger

name: "ci-fix"
description: "Debug CI/CD failures for backend (ktlint, compile, test, build)"
parameters:
  - name: "error_type"
    description: "Failure type: ktlint, compile, test, build, all"
    required: true
  - name: "error_log"
    description: "Paste error output or path to log file"
    required: false

---

You are an expert developer debugging CI/CD failures for the MunServ backend.

## Task

Debug and fix `{{error_type}}` failure(s) in the backend CI/CD pipeline.

## CI Commands Reference

```bash
./gradlew ktlintCheck      # Code style check
./gradlew compileKotlin    # Compilation
./gradlew test             # Unit + integration tests
./gradlew build            # Full build (includes all above)
./gradlew sonar            # SonarQube analysis
```

## Debugging by Error Type

### ktlint Failures (Code Style)

**Run locally:**
```bash
./gradlew ktlintCheck
# or with auto-fix
./gradlew ktlintFormat
```

**Common ktlint Errors:**

#### Wildcard Import
```
Wildcard import (cannot be auto-corrected)
```
**Fix:** Replace with explicit imports
```kotlin
// Before
import com.example.*

// After
import com.example.Class1
import com.example.Class2
```

#### Trailing Comma
```
Missing trailing comma before ")"
```
**Fix:** Add trailing comma (project uses trailing commas)
```kotlin
// Before
data class Example(
    val a: String,
    val b: Int
)

// After
data class Example(
    val a: String,
    val b: Int,
)
```

#### Import Order
```
Imports must be ordered
```
**Fix:** Run `./gradlew ktlintFormat` or reorder imports:
```kotlin
// Order: stdlib → third-party → project
import java.time.Instant
import java.util.UUID

import org.springframework.stereotype.Service

import com.munserv.issues.domain.Issue
```

#### Max Line Length
```
Exceeded max line length (120)
```
**Fix:** Break line appropriately
```kotlin
// Before
fun veryLongMethodName(param1: String, param2: String, param3: String): VeryLongReturnType = implementation()

// After
fun veryLongMethodName(
    param1: String,
    param2: String,
    param3: String,
): VeryLongReturnType = implementation()
```

### Compile Failures (Kotlin)

**Run locally:**
```bash
./gradlew compileKotlin
./gradlew compileTestKotlin
```

**Common Compilation Errors:**

#### Unresolved Reference
```
Unresolved reference: ClassName
```
**Fix:** Add missing import or dependency
```kotlin
// Check if class exists
// Check if import is correct
// Check if dependency is in build.gradle.kts
```

#### Type Mismatch
```
Type mismatch: inferred type is X but Y was expected
```
**Fix:** Correct the type or add conversion
```kotlin
// Before
val id: UUID = issueId  // IssueId

// After
val id: UUID = issueId.value
```

#### Missing Override
```
'method' overrides nothing
```
**Fix:** Check interface/parent class method signature
```kotlin
// Ensure method signature matches exactly
override fun findById(id: IssueId): Issue?
```

#### Null Safety
```
Only safe (?.) or non-null asserted (!!) calls are allowed
```
**Fix:** Add null handling
```kotlin
// Before
issue.property.method()

// After
issue?.property?.method()
// or
issue?.let { it.property.method() }
```

### Test Failures (JUnit/Kotest)

**Run locally:**
```bash
./gradlew test
# or specific test
./gradlew test --tests "*.IssueServiceTest"
# with verbose output
./gradlew test --info
```

**Common Test Failures:**

#### Assertion Failed
```
expected: <X> but was: <Y>
```
**Fix:** Check test expectations or implementation
```kotlin
// Debug: Add logging or breakpoint
println("Actual value: $result")

// Verify test data setup
// Verify implementation logic
```

#### Mock Not Called
```
Verification failed: call 1 of 1: repository.save(any()) was not called
```
**Fix:** Check mock setup and method invocation
```kotlin
// Ensure mock is set up
every { repository.save(any()) } returns entity

// Ensure method actually calls the mock
verify { repository.save(any()) }
```

#### TestContainers Timeout
```
Container startup failed
```
**Fix:**
```kotlin
// Increase timeout or check Docker
@Container
val postgres = PostgreSQLContainer(...)
    .withStartupTimeout(Duration.ofMinutes(2))

// Ensure Docker is running
docker ps
```

#### Spring Context Failed
```
Failed to load ApplicationContext
```
**Fix:** Check configuration
```kotlin
// Ensure test profile exists
@ActiveProfiles("test")

// Check application-test.yml exists
// Verify all beans can be created
```

### Build Failures (Gradle)

**Run locally:**
```bash
./gradlew build
./gradlew build --stacktrace
```

**Common Build Errors:**

#### Dependency Resolution
```
Could not resolve: com.example:library:1.0
```
**Fix:** Check repositories and dependency version
```kotlin
// build.gradle.kts
repositories {
    mavenCentral()
}

dependencies {
    implementation("com.example:library:1.0")
}
```

#### Resource Not Found
```
FileNotFoundException: application.yml
```
**Fix:** Ensure file is in correct location
```
src/main/resources/application.yml
src/test/resources/application-test.yml
```

## Quick Fix Workflow

1. **Identify error type** from CI log
2. **Run locally** to reproduce
3. **Apply fix** based on patterns above
4. **Verify fix** by re-running command
5. **Commit and push**

## Full CI Check Before Commit

```bash
# Run all checks
./gradlew ktlintCheck && ./gradlew test && ./gradlew build
```

## Common Fix Commands

```bash
# Auto-format code
./gradlew ktlintFormat

# Clear Gradle cache
./gradlew clean

# Refresh dependencies
./gradlew --refresh-dependencies

# Run with debug info
./gradlew build --stacktrace --info
```

## Output

1. **Parse** error log to identify failure type
2. **Reproduce** locally with appropriate command
3. **Diagnose** root cause using patterns above
4. **Fix** the issue
5. **Verify** fix passes locally
6. **Report** what was fixed
