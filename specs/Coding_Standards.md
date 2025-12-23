# Coding Standards

**Project:** MunServ | **Version:** 1.0 | **Status:** Approved

*Companion to Architecture_and_Design_Patterns.md. Include both as LLM context.*

---

## 1. Universal Rules

| Rule | Standard |
|------|----------|
| Line length | 120 characters max |
| Indentation | 4 spaces (no tabs) |
| Trailing whitespace | None |
| File ending | Single newline |
| Imports | Explicit only, no wildcards |
| Function length | ≤30 lines, extract if longer |
| Nesting depth | ≤3 levels, extract if deeper |
| Comments | Explain *why*, not *what* |

---

## 2. Kotlin (Backend)

### 2.1 Naming

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `IssueService`, `MemberEntity` |
| Interfaces | PascalCase (no prefix) | `IssueRepository` ✅ `IIssueRepository` ❌ |
| Functions | camelCase | `findById`, `calculateHeat` |
| Variables | camelCase | `issueCount`, `currentMember` |
| Constants | SCREAMING_SNAKE | `MAX_PHOTOS`, `DEFAULT_PAGE_SIZE` |
| Packages | lowercase.dot.separated | `com.munserv.issues.domain` |
| Files | PascalCase matching class | `IssueService.kt` |

### 2.2 Type Conventions

```kotlin
// Value objects for type safety - ALWAYS for IDs
@JvmInline value class IssueId(val value: UUID)
@JvmInline value class SectorId(val value: UUID)

// Domain entities - pure data classes, no JPA annotations
data class Issue(val id: IssueId, val type: IssueType, ...)

// JPA entities - separate in repository layer
@Entity @Table(name = "issues")
class IssueEntity(...)

// DTOs - separate request/response classes
data class CreateIssueRequest(...)
data class IssueResponse(...)

// States and results - sealed classes/interfaces
sealed interface IssueResult { ... }
sealed class IssueState { ... }
```

### 2.3 Null Handling

```kotlin
// ✅ DO: Safe calls with let
user?.let { sendNotification(it) }

// ✅ DO: Elvis for defaults
val name = user?.name ?: "Unknown"

// ✅ DO: Early return for null checks
fun process(id: IssueId): IssueResult {
    val issue = repository.findById(id)
        ?: return IssueResult.NotFound(id)
    // continue with non-null issue
}

// ❌ DON'T: Force unwrap
val name = user!!.name

// ❌ DON'T: Nested null checks
if (user != null) {
    if (user.address != null) { ... }
}
```

### 2.4 Collections & Lambdas

```kotlin
// ✅ DO: Functional chains
issues.filter { it.state == Open }
      .sortedByDescending { it.heat }
      .take(10)

// ✅ DO: mapNotNull for filter+map
members.mapNotNull { it.email }

// ❌ DON'T: forEach with side effects for transformation
val results = mutableListOf<T>()
items.forEach { results.add(transform(it)) } // use map instead
```

### 2.5 Coroutines

```kotlin
// ✅ DO: suspend functions in services
suspend fun findById(id: IssueId): Issue?

// ✅ DO: withContext for blocking operations
suspend fun loadPhoto(id: PhotoId): ByteArray = 
    withContext(Dispatchers.IO) { storage.download(id) }

// ❌ DON'T: runBlocking in production code
// ❌ DON'T: GlobalScope.launch
```

### 2.6 Import Order

```kotlin
// 1. Java/Kotlin stdlib
import java.util.UUID
import kotlin.collections.List

// 2. Third-party libraries
import org.springframework.stereotype.Service
import io.ktor.client.HttpClient

// 3. Project imports
import com.munserv.issues.domain.Issue
import com.munserv.shared.types.GeoPoint
```

---

## 3. Dart/Flutter (Mobile)

### 3.1 Naming

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `IssueRepository`, `ReportPage` |
| Functions/methods | camelCase | `fetchIssues`, `onTapSubmit` |
| Variables | camelCase | `issueList`, `isLoading` |
| Constants | camelCase or SCREAMING_SNAKE | `defaultPadding`, `API_BASE_URL` |
| Files | snake_case | `issue_repository.dart`, `report_page.dart` |
| Folders | snake_case | `features/issues/presentation/` |

### 3.2 Type Conventions

```dart
// ✅ DO: Freezed for immutable models
@freezed
class Issue with _$Issue {
  const factory Issue({
    required String id,
    required IssueType type,
    required IssueState state,
  }) = _Issue;
  
  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
}

// ✅ DO: Enums for fixed sets
enum IssueState { reported, confirmed, inProgress, fixed, rejected, reopened }

// ✅ DO: Typedef for complex function signatures
typedef IssueCallback = void Function(Issue issue);
```

### 3.3 Null Safety

```dart
// ✅ DO: Required named parameters
void submitIssue({required String title, required GeoPoint location}) { }

// ✅ DO: Null-aware operators
final name = user?.name ?? 'Unknown';
final issues = response.data?.issues ?? [];

// ✅ DO: Early return
if (user == null) return;

// ❌ DON'T: late unless necessary (controllers, animation)
late final String name; // avoid

// ❌ DON'T: Force unwrap without check
final name = user!.name; // only after null check
```

### 3.4 Widget Rules

```dart
// ✅ DO: const constructors
const IssueCard({super.key, required this.issue});

// ✅ DO: Extract widgets at ~50 lines
// ✅ DO: Private widgets in same file if single-use
class _IssueCardHeader extends StatelessWidget { }

// ✅ DO: Prefer StatelessWidget + Riverpod over StatefulWidget

// ❌ DON'T: Business logic in build()
// ❌ DON'T: Deep widget nesting (>4 levels) - extract
```

### 3.5 Async Patterns

```dart
// ✅ DO: AsyncValue with Riverpod
final issuesAsync = ref.watch(issuesProvider);
return issuesAsync.when(
  data: (issues) => IssueList(issues: issues),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(error: e),
);

// ✅ DO: try/catch at repository level, return Result type
Future<Result<Issue>> fetchIssue(String id) async {
  try {
    final response = await api.get('/issues/$id');
    return Result.success(Issue.fromJson(response.data));
  } catch (e) {
    return Result.failure(e);
  }
}
```

### 3.6 Import Order

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:riverpod/riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 4. Project imports (relative within feature, package across features)
import '../domain/issue.dart';
import 'package:munserv/shared/widgets/loading_spinner.dart';
```

---

## 4. TypeScript/React (Web Admin)

### 4.1 Naming

| Element | Convention | Example |
|---------|------------|---------|
| Components | PascalCase | `IssueList`, `HeatMap` |
| Hooks | camelCase with `use` prefix | `useIssues`, `useSectorFilter` |
| Functions | camelCase | `formatDate`, `calculateHeat` |
| Variables | camelCase | `issueCount`, `isLoading` |
| Constants | SCREAMING_SNAKE or camelCase | `API_BASE_URL`, `defaultPageSize` |
| Files (components) | PascalCase | `IssueList.tsx` |
| Files (utilities) | camelCase | `formatters.ts`, `api.ts` |
| Folders | kebab-case | `features/issues/`, `shared/hooks/` |

### 4.2 Type Conventions

```typescript
// ✅ DO: interface for object shapes
interface Issue {
  id: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
}

// ✅ DO: type for unions and aliases
type IssueState = 'reported' | 'confirmed' | 'in_progress' | 'fixed' | 'rejected';
type IssueCallback = (issue: Issue) => void;

// ✅ DO: Props interface per component
interface IssueCardProps {
  issue: Issue;
  onSelect?: (issue: Issue) => void;
}

// ❌ DON'T: any type
// ❌ DON'T: non-null assertion without check (!)
```

### 4.3 Component Patterns

```typescript
// ✅ DO: Arrow function with explicit return type
const IssueCard = ({ issue, onSelect }: IssueCardProps): JSX.Element => {
  return (
    <div onClick={() => onSelect?.(issue)}>
      {issue.title}
    </div>
  );
};

// ✅ DO: Destructure props
const IssueList = ({ issues, isLoading }: IssueListProps) => { ... };

// ✅ DO: Default export for pages, named export for components
export const IssueCard = ...;       // component
export default function IssuesPage() { ... }  // page

// ❌ DON'T: Class components
// ❌ DON'T: Inline object/function creation in JSX (causes re-renders)
<Button onClick={() => handleClick(id)} />  // extract if in loop
```

### 4.4 Hooks Rules

```typescript
// ✅ DO: Custom hooks for data fetching
function useIssues(sectorId: string) {
  return useQuery({
    queryKey: ['issues', sectorId],
    queryFn: () => issueApi.getBySector(sectorId),
  });
}

// ✅ DO: useMemo for expensive computations
const sortedIssues = useMemo(
  () => issues.sort((a, b) => b.heat - a.heat),
  [issues]
);

// ✅ DO: useCallback for handlers passed to children
const handleSelect = useCallback((issue: Issue) => {
  setSelected(issue.id);
}, []);

// ❌ DON'T: useEffect for data fetching (use React Query)
// ❌ DON'T: useState for server state (use React Query)
```

### 4.5 Import Order

```typescript
// 1. React
import { useState, useCallback } from 'react';

// 2. Third-party libraries
import { useQuery } from '@tanstack/react-query';
import { clsx } from 'clsx';

// 3. Project absolute imports
import { Button } from '@/components/atoms/Button';
import { useAuth } from '@/shared/hooks/useAuth';

// 4. Relative imports
import { IssueCard } from './IssueCard';
import type { Issue } from '../types';
```

---

## 5. SQL/Database

### 5.1 Naming

| Element | Convention | Example |
|---------|------------|---------|
| Tables | snake_case plural | `issues`, `sector_members` |
| Columns | snake_case | `created_at`, `sector_id` |
| Primary keys | `id` | `id UUID PRIMARY KEY` |
| Foreign keys | `{table}_id` | `sector_id`, `reporter_id` |
| Indexes | `idx_{table}_{columns}` | `idx_issues_sector_id` |
| Constraints | `{type}_{table}_{column}` | `fk_issues_sector`, `uq_members_phone` |

### 5.2 Query Style

```sql
-- ✅ DO: UPPER keywords, lower identifiers
SELECT i.id, i.type, i.state, s.name AS sector_name
FROM issues i
INNER JOIN sectors s ON s.id = i.sector_id
WHERE i.state = 'reported'
  AND i.created_at > :since
ORDER BY i.heat DESC
LIMIT :limit;

-- ✅ DO: Explicit column lists (never SELECT *)
-- ✅ DO: Table aliases for joins
-- ✅ DO: Named parameters (:param)

-- ❌ DON'T: SELECT *
-- ❌ DON'T: Implicit joins (comma syntax)
```

---

## 6. Forbidden Patterns

### 6.1 All Languages

| ❌ Never | Why |
|----------|-----|
| Magic numbers/strings | Use named constants |
| Deep nesting (>3 levels) | Extract to functions |
| Long functions (>30 lines) | Single responsibility |
| Commented-out code | Delete it, use git |
| Print/console debugging | Use proper logging |
| Hardcoded secrets | Use environment variables |

### 6.2 Kotlin Specific

| ❌ Never | ✅ Instead |
|----------|-----------|
| `!!` (force unwrap) | `?.let {}` or `?: return` |
| `var` for state | `val` + copy |
| Exceptions for flow control | Sealed Result types |
| `@Autowired` on fields | Constructor injection |
| Mutable collections in APIs | `List` not `MutableList` |

### 6.3 Dart/Flutter Specific

| ❌ Never | ✅ Instead |
|----------|-----------|
| `late` (except controllers) | Nullable + null check |
| `setState` for complex state | Riverpod providers |
| Business logic in widgets | Extract to providers/services |
| `dynamic` type | Proper typing |
| Deeply nested widgets | Extract sub-widgets |

### 6.4 TypeScript/React Specific

| ❌ Never | ✅ Instead |
|----------|-----------|
| `any` type | Proper interface/type |
| Class components | Functional + hooks |
| `useEffect` for fetching | React Query |
| Prop drilling (>2 levels) | Context or state management |
| Index as key in lists | Stable unique ID |
| Inline handlers in loops | `useCallback` + extract |

---

## 7. File Templates

### 7.1 Kotlin Service

```kotlin
package com.munserv.{module}.service

import com.munserv.{module}.domain.*
import com.munserv.{module}.repository.{Entity}Repository
import org.springframework.stereotype.Service

@Service
class {Name}Service(
    private val repository: {Entity}Repository,
) {
    fun findById(id: {Entity}Id): {Result} {
        // implementation
    }
}
```

### 7.2 Flutter Provider

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/{name}_repository.dart';
import '../domain/{name}.dart';

part '{name}_providers.g.dart';

@riverpod
Future<List<{Name}>> {name}s({Name}sRef ref) async {
  final repository = ref.watch({name}RepositoryProvider);
  final result = await repository.getAll();
  return result.getOrThrow();
}
```

### 7.3 React Component

```typescript
import { type FC } from 'react';
import { clsx } from 'clsx';

interface {Name}Props {
  // props
}

export const {Name}: FC<{Name}Props> = ({ ...props }) => {
  return (
    <div className={clsx('...')}>
      {/* content */}
    </div>
  );
};
```

---

*Document optimized for LLM context. Include with Architecture_and_Design_Patterns.md when generating code.*
