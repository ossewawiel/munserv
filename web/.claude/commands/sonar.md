# SonarQube Analysis & Fixes

name: "sonar"
description: "Run SonarQube analysis, report issues, and optionally auto-fix"
parameters:
  - name: "scope"
    description: "Analysis scope: full, changed, feature"
    required: true
  - name: "fix"
    description: "Auto-fix issues: true or false"
    required: false
    default: "false"
  - name: "feature"
    description: "Feature folder to analyze (if scope=feature)"
    required: false

---

You are an expert developer analyzing code quality using SonarQube for the MunServ web admin portal.

## Task

Analyze code quality {{#if feature}}for `{{feature}}`{{else}}{{#if scope == "changed"}}for changed files{{else}}for the entire web project{{/if}}{{/if}} using SonarQube.

## MCP Tools Available

Use these SonarQube MCP tools:

```typescript
// Check quality gate status
mcp__sonarqube__get_project_quality_gate_status({
  projectKey: 'munserv-web'
})

// Search for issues
mcp__sonarqube__search_sonar_issues_in_projects({
  projects: ['munserv-web'],
  severities: ['BLOCKER', 'CRITICAL', 'MAJOR'],
  ps: 100  // page size
})

// Get rule details
mcp__sonarqube__show_rule({
  key: 'typescript:S1234'
})
```

## Analysis Workflow

### Step 1: Check Quality Gate
```
Call: mcp__sonarqube__get_project_quality_gate_status
Expected: Status should be "OK" or "WARN"
```

### Step 2: Get Issues by Severity
```
Call: mcp__sonarqube__search_sonar_issues_in_projects
Severities: BLOCKER, CRITICAL, MAJOR, MINOR, INFO
```

### Step 3: Categorize Issues

| SonarQube Severity | Project Severity | Action |
|-------------------|------------------|--------|
| BLOCKER | CRITICAL | Must fix immediately |
| CRITICAL | CRITICAL | Must fix before merge |
| MAJOR | HIGH | Should fix |
| MINOR | MEDIUM | Consider fixing |
| INFO | LOW | Nice to have |

## Common SonarQube Rules for React/TypeScript

### Code Smells
- `typescript:S1854` - Unused variable
- `typescript:S1481` - Unused local variable
- `typescript:S1128` - Unused import
- `typescript:S3776` - Cognitive complexity too high
- `typescript:S1066` - Collapsible if statements
- `typescript:S1135` - TODO/FIXME comments

### Bugs
- `typescript:S2201` - Return value should be used
- `typescript:S2583` - Condition always true/false
- `typescript:S3923` - Identical conditions

### Vulnerabilities
- `typescript:S1313` - Using hardcoded IP
- `typescript:S2068` - Hardcoded credentials
- `typescript:S5604` - Using console.log (in production)

### Security Hotspots
- `typescript:S5131` - DOM XSS vulnerability
- `typescript:S2077` - SQL injection (unlikely in frontend)

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

1. **[typescript:SXXXX]** Issue description
   - File: `src/path/to/file.ts:42`
   - Message: Detailed message from SonarQube
   - Fix: Suggested solution

#### MAJOR

1. **[typescript:SXXXX]** Issue description
   - File: `src/path/to/file.ts:15`
   - Message: ...
   - Fix: ...
```

## Auto-Fix Patterns

If `{{fix}}` is true, apply these fixes:

### Unused Imports (S1128)
```typescript
// Before
import { useState, useEffect, useMemo } from 'react'; // useMemo unused

// After
import { useState, useEffect } from 'react';
```

### Unused Variables (S1854)
```typescript
// Before
const unused = calculateValue();
doSomething();

// After (remove or use)
doSomething();
```

### Console Logs (S5604)
```typescript
// Before
console.log('debug:', data);

// After (remove in production code)
// or use proper logging
logger.debug('debug:', data);
```

### Cognitive Complexity (S3776)
```typescript
// Before - nested conditions
if (a) {
  if (b) {
    if (c) {
      // ...
    }
  }
}

// After - early returns
if (!a) return;
if (!b) return;
if (!c) return;
// ...
```

### Collapsible If (S1066)
```typescript
// Before
if (a) {
  if (b) {
    // ...
  }
}

// After
if (a && b) {
  // ...
}
```

## Integration with CI

The project has SonarQube configured in:
- `web/sonar-project.properties`

To run analysis locally:
```bash
# Ensure SonarQube server is running
docker compose up -d sonarqube

# Run analysis
pnpm sonar
```

## Output

1. **Fetch** quality gate status using MCP
2. **Fetch** issues by severity using MCP
3. **Categorize** issues by type and severity
4. **Report** findings in structured format
5. **Fix** issues if `{{fix}}` is true
6. **Verify** fixes by re-running relevant checks
