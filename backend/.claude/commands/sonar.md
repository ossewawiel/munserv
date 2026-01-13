# SonarQube Analysis & Fixes

name: "sonar"
description: "Run SonarQube analysis and report issues"
parameters:
  - name: "scope"
    description: "Analysis scope: full, changed, feature"
    required: true
  - name: "fix"
    description: "Auto-fix issues: true or false"
    required: false
    default: "false"
  - name: "feature"
    description: "Feature folder (if scope=feature)"
    required: false

---

You are an expert developer analyzing code quality using SonarQube for the MunServ backend.

## Task

Analyze code quality {{#if feature}}for `{{feature}}`{{else}}{{#if scope == "changed"}}for changed files{{else}}for the entire backend project{{/if}}{{/if}} using SonarQube.

## MCP Tools Available

Use these SonarQube MCP tools:

```kotlin
// Check quality gate status
mcp__sonarqube__get_project_quality_gate_status({
  projectKey: 'munserv-backend'
})

// Search for issues
mcp__sonarqube__search_sonar_issues_in_projects({
  projects: ['munserv-backend'],
  severities: ['BLOCKER', 'CRITICAL', 'MAJOR'],
  ps: 100  // page size
})

// Get rule details
mcp__sonarqube__show_rule({
  key: 'kotlin:S1234'
})
```

## Analysis Workflow

### Step 1: Run SonarQube Analysis (if needed)

```bash
# Generate coverage report first
./gradlew test jacocoTestReport

# Run SonarQube analysis
./gradlew sonar
```

### Step 2: Check Quality Gate

```
Call: mcp__sonarqube__get_project_quality_gate_status
Project Key: munserv-backend
Expected: Status should be "OK" or "WARN"
```

### Step 3: Get Issues by Severity

```
Call: mcp__sonarqube__search_sonar_issues_in_projects
Severities: BLOCKER, CRITICAL, MAJOR, MINOR, INFO
```

### Step 4: Categorize Issues

| SonarQube Severity | Project Severity | Action |
|-------------------|------------------|--------|
| BLOCKER | CRITICAL | Must fix immediately |
| CRITICAL | CRITICAL | Must fix before merge |
| MAJOR | HIGH | Should fix |
| MINOR | MEDIUM | Consider fixing |
| INFO | LOW | Nice to have |

## Common SonarQube Rules for Kotlin

### Code Smells
- `kotlin:S1481` - Unused local variable
- `kotlin:S1186` - Empty function body
- `kotlin:S3776` - Cognitive complexity too high
- `kotlin:S1135` - TODO/FIXME comments
- `kotlin:S1128` - Unused import

### Bugs
- `kotlin:S2201` - Return value should be used
- `kotlin:S2583` - Condition always true/false
- `kotlin:S2259` - Null pointer dereference

### Vulnerabilities
- `kotlin:S2068` - Hardcoded credentials
- `kotlin:S5131` - Unsafe deserialization
- `kotlin:S4790` - Weak cryptography

### Security Hotspots
- `kotlin:S2245` - Using pseudo-random number generators
- `kotlin:S5042` - Expanding archive files

## Issue Report Format

```markdown
## SonarQube Analysis Report

### Quality Gate Status: {{status}}

### Issues by Severity

| Severity | Count |
|----------|-------|
| BLOCKER | X |
| CRITICAL | X |
| MAJOR | X |
| MINOR | X |

### Top Issues to Address

#### BLOCKER/CRITICAL

1. **[kotlin:SXXXX]** Issue description
   - File: `src/main/kotlin/.../File.kt:42`
   - Message: Detailed message from SonarQube
   - Fix: Suggested solution

#### MAJOR

1. **[kotlin:SXXXX]** Issue description
   - File: `src/main/kotlin/.../File.kt:15`
   - Message: ...
   - Fix: ...
```

## Auto-Fix Patterns

If `{{fix}}` is true, apply these fixes:

### Unused Variables (S1481)
```kotlin
// Before
val unused = calculateValue()
doSomething()

// After (if needed for side effect)
calculateValue() // or remove if truly unused
doSomething()
```

### Cognitive Complexity (S3776)
```kotlin
// Before - nested conditions
if (a) {
    if (b) {
        if (c) {
            // ...
        }
    }
}

// After - early returns
if (!a) return
if (!b) return
if (!c) return
// ...
```

### TODO Comments (S1135)
```kotlin
// Before
// TODO: Implement this later

// After - create issue tracker item and reference
// See: ISSUE-123 - Implement feature X
```

### Unused Imports (S1128)
```kotlin
// Before
import com.example.unused.Class
import com.example.used.Class

// After
import com.example.used.Class
```

## Gradle Commands

```bash
# Run all tests with coverage
./gradlew test jacocoTestReport

# Run SonarQube analysis
./gradlew sonar

# Run specific test class
./gradlew test --tests "*.IssueServiceTest"

# Check coverage report
open build/reports/jacoco/test/html/index.html
```

## SonarQube Configuration

From `build.gradle.kts`:
```kotlin
sonarqube {
    properties {
        property("sonar.projectKey", "munserv-backend")
        property("sonar.host.url", "http://localhost:9000")
        property("sonar.sources", "src/main/kotlin")
        property("sonar.tests", "src/test/kotlin")
        property("sonar.coverage.jacoco.xmlReportPaths",
                 "build/reports/jacoco/test/jacocoTestReport.xml")
    }
}
```

## Output

1. **Fetch** quality gate status using MCP
2. **Fetch** issues by severity using MCP
3. **Categorize** issues by type and severity
4. **Report** findings in structured format
5. **Fix** issues if `{{fix}}` is true
6. **Verify** fixes by re-running `./gradlew test`
