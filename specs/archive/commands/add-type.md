# Add Shared Type

name: "add-type"
description: "Add shared data type"
parameters:
  - name: "name"
    description: "Type name (e.g., 'Issue', 'Member')"
    required: true
  - name: "fields"
    description: "Fields as 'name:type' (pipe-separated)"
    required: true
  - name: "notes"
    description: "Additional notes (pipe-separated)"
    required: false

---

## Task

Add type "{{name}}" to `specs/contracts/types.md`.

## Context

Read first:
1. `specs/contracts/types.md` - Existing types
2. `specs/contracts/api.md` - Where type is used

## Process

### Step 1: Parse Fields

Convert "{{fields}}" to structured format:
- Input: `id:IssueId|title:string|state:IssueState|location:GeoPoint`
- Output: Table rows

### Step 2: Format Type

```markdown
## {{name}}

| Field | Type | Notes |
|-------|------|-------|
{{#each fields}}
| {{name}} | {{type}} | {{note}} |
{{/each}}
```

### Step 3: Add to Document

Insert in `specs/contracts/types.md` in alphabetical order.

### Step 4: Cross-reference

Check if this type is used in API endpoints and feature specs.

## Type Template

### Entity Type
```markdown
## Issue

| Field | Type | Notes |
|-------|------|-------|
| id | IssueId | UUID wrapper |
| title | string | max 100 chars |
| description | string? | optional, max 1000 |
| state | IssueState | enum |
| location | GeoPoint | lat/lng |
| photos | Photo[] | max 5 |
| reporterId | MemberId | who reported |
| createdAt | DateTime | ISO 8601 |
| updatedAt | DateTime | ISO 8601 |
```

### Enum Type
```markdown
## IssueState

| Value | Description |
|-------|-------------|
| REPORTED | Initial state |
| CONFIRMED | Verified by admin |
| IN_PROGRESS | Being addressed |
| FIXED | Resolved |
| REJECTED | Not valid |
```

### Value Object
```markdown
## GeoPoint

| Field | Type | Notes |
|-------|------|-------|
| lat | number | -90 to 90 |
| lng | number | -180 to 180 |
```

### ID Wrapper
```markdown
## IssueId

UUID wrapper type for Issue identifiers.
- Format: UUID v4
- Example: `550e8400-e29b-41d4-a716-446655440000`
```

## Type Conventions

| Convention | Example |
|------------|---------|
| ID wrapper | `MemberId`, `IssueId` |
| Nullable | `string?` |
| Array | `Photo[]` |
| DateTime | ISO 8601 format |
| Enum | ALL_CAPS values |

## Platform Mappings

| Contract | Kotlin | TypeScript | Dart |
|----------|--------|------------|------|
| string | String | string | String |
| number | Int/Long | number | int |
| boolean | Boolean | boolean | bool |
| DateTime | Instant | string | DateTime |
| UUID | UUID | string | String |

## Quality Checklist

- [ ] Type name is PascalCase
- [ ] All fields have types
- [ ] Nullable fields marked with ?
- [ ] Notes explain constraints

## Next Steps

After adding type:
1. Use in API endpoint: `/add-endpoint`
2. Reference in feature spec
3. Implement in each platform during `/dev-cycle`
