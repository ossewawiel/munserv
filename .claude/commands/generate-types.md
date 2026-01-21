# Generate Types

name: "generate-types"
description: "Generate platform types from specs/contracts/types.md"
parameters:
  - name: "type"
    description: "Specific type to generate, or 'all'"
    default: "all"
  - name: "platform"
    description: "Target platform: kotlin, typescript, dart, or all"
    default: "all"
  - name: "dry_run"
    description: "Preview changes without writing files"
    default: "false"

---

## Task

Generate type definitions across platforms from the single source of truth in `specs/contracts/types.md`.

## Context

Type definitions (especially enums) must be consistent across:
- Backend (Kotlin): `backend/src/main/kotlin/com/munserv/shared/enums/`
- Web (TypeScript): `web/src/types/` or feature-specific types
- Mobile (Dart): `mobile/lib/shared/models/`

This skill reads annotated type definitions from specs and generates platform-specific code.

## Source Format

`specs/contracts/types.md` uses annotations:

```markdown
## GroundAdminStatus
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description | Since |
|-------|-------------|-------|
| pending | Awaiting approval | v1.0 |
| approved | Active ground admin | v1.0 |
| rejected | Application denied | v1.0 |
| revoked | Access removed | v1.1 |

## IssueState
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| reported | Initial state |
| confirmed | Verified by admin |
| in_progress | Being worked on |
| fixed | Issue resolved |
| wont_fix | Closed without fix |
```

## Process

### Step 1: Parse Type Definitions

Read `specs/contracts/types.md` and extract:
- Type name
- Type kind (@enum, @interface, @type)
- Target platforms (@generate)
- Serialization format (@serialization)
- Values/fields

### Step 2: Validate Definitions

Check for:
- [ ] All required annotations present
- [ ] No duplicate values
- [ ] Valid serialization format
- [ ] Consistent naming conventions

### Step 3: Generate Kotlin

For enums with `@generate(kotlin)`:

```kotlin
package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonValue

/**
 * {{description}}
 * Generated from specs/contracts/types.md
 */
enum class {{TypeName}}(
    @JsonValue val value: String
) {
    {{#values}}
    {{CONSTANT_CASE}}("{{snake_case}}"),
    {{/values}}
    ;

    companion object {
        fun fromValue(value: String): {{TypeName}}? =
            entries.find { it.value == value }
    }
}
```

Output: `backend/src/main/kotlin/com/munserv/shared/enums/{{TypeName}}.kt`

### Step 4: Generate TypeScript

For enums with `@generate(typescript)`:

```typescript
/**
 * {{description}}
 * Generated from specs/contracts/types.md
 */
export const {{TypeName}} = {
  {{#values}}
  {{CONSTANT_CASE}}: '{{snake_case}}',
  {{/values}}
} as const;

export type {{TypeName}} = typeof {{TypeName}}[keyof typeof {{TypeName}}];

export const {{typeName}}Values = Object.values({{TypeName}});

export function is{{TypeName}}(value: unknown): value is {{TypeName}} {
  return {{typeName}}Values.includes(value as {{TypeName}});
}
```

Output: `web/src/types/{{type-name}}.ts`

### Step 5: Generate Dart

For enums with `@generate(dart)`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

/// {{description}}
/// Generated from specs/contracts/types.md
enum {{TypeName}} {
  {{#values}}
  @JsonValue('{{snake_case}}')
  {{camelCase}},
  {{/values}}
}

extension {{TypeName}}Extension on {{TypeName}} {
  String get value {
    switch (this) {
      {{#values}}
      case {{TypeName}}.{{camelCase}}:
        return '{{snake_case}}';
      {{/values}}
    }
  }

  static {{TypeName}}? fromValue(String value) {
    switch (value) {
      {{#values}}
      case '{{snake_case}}':
        return {{TypeName}}.{{camelCase}};
      {{/values}}
      default:
        return null;
    }
  }
}
```

Output: `mobile/lib/shared/enums/{{type_name}}.dart`

### Step 6: Update Index Files

**Kotlin:** No index needed (package structure)

**TypeScript:** Update `web/src/types/index.ts`:
```typescript
export * from './{{type-name}}';
```

**Dart:** Update `mobile/lib/shared/enums/enums.dart`:
```dart
export '{{type_name}}.dart';
```

### Step 7: Validate Generated Code

Run platform-specific validation:
```bash
# Kotlin - compile check
cd backend && ./gradlew compileKotlin

# TypeScript - type check
cd web && pnpm tsc --noEmit

# Dart - analyze
cd mobile && flutter analyze
```

## Output Format

### Dry Run
```markdown
## Type Generation Preview

### Types to Generate
- GroundAdminStatus: kotlin, typescript, dart
- IssueState: kotlin, typescript, dart

### Files to Create/Update

**Kotlin:**
- backend/src/main/kotlin/com/munserv/shared/enums/GroundAdminStatus.kt
- backend/src/main/kotlin/com/munserv/shared/enums/IssueState.kt

**TypeScript:**
- web/src/types/ground-admin-status.ts
- web/src/types/issue-state.ts
- web/src/types/index.ts (update)

**Dart:**
- mobile/lib/shared/enums/ground_admin_status.dart
- mobile/lib/shared/enums/issue_state.dart
- mobile/lib/shared/enums/enums.dart (update)

Run `/generate-types dry_run=false` to generate files.
```

### Generated
```markdown
## Types Generated

### Files Created
- backend/src/main/kotlin/com/munserv/shared/enums/GroundAdminStatus.kt
- backend/src/main/kotlin/com/munserv/shared/enums/IssueState.kt
- web/src/types/ground-admin-status.ts
- web/src/types/issue-state.ts
- mobile/lib/shared/enums/ground_admin_status.dart
- mobile/lib/shared/enums/issue_state.dart

### Validation
- Kotlin: Compiled successfully
- TypeScript: Type check passed
- Dart: Analysis passed

### Next Steps
1. Review generated code
2. Run tests: `./gradlew test`, `pnpm test`, `flutter test`
3. Commit changes
```

## Quality Checklist

- [ ] Source types.md is valid
- [ ] All annotations parsed correctly
- [ ] Generated code compiles/analyzes
- [ ] Serialization format matches API contract
- [ ] Index files updated
- [ ] No duplicate definitions

## Error Handling

**Parse error:**
```
Error: Could not parse type definition at line {{line}}
Expected format: ## TypeName followed by @annotations

Please check specs/contracts/types.md
```

**Missing annotation:**
```
Warning: {{TypeName}} missing @serialization annotation
Defaulting to snake_case
```

**Compile error:**
```
Error: Generated Kotlin code failed to compile
File: {{path}}
Error: {{compiler_error}}

Please fix the type definition in specs/contracts/types.md
```

## Integration

Related workflows:
- `.github/workflows/validate-specs.yml` - Checks enum sync
- `/sync-github` - Includes type drift detection

Related skills:
- `/add-type` - Adds new type to specs/contracts/types.md
