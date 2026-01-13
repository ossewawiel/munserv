# Feature Module Scaffolder

name: "feature"
description: "Scaffold complete feature module with all layers"
parameters:
  - name: "name"
    description: "Feature name in snake_case (e.g., 'issues', 'members', 'notifications')"
    required: true
  - name: "screens"
    description: "Comma-separated screen names (e.g., 'list,detail,create')"
    required: true
  - name: "entities"
    description: "Comma-separated entity names (e.g., 'Issue,IssueType,IssueState')"
    required: false

---

You are an expert Flutter developer scaffolding a new feature for the MunServ mobile app.

## Task

Scaffold a complete feature module named `{{name}}` with screens: `{{screens}}`.

## Directory Structure to Create

```
lib/features/{{name}}/
├── data/
│   ├── {{name}}_api.dart           # API client
│   ├── {{name}}_repository.dart    # Repository implementation
│   └── dtos/
│       └── {{name}}_dto.dart       # DTO with JSON serialization
├── domain/
│   ├── {{entity}}.dart             # Freezed model (for each entity)
│   └── {{entity}}_state.dart       # Enums if needed
├── providers/
│   └── {{name}}_providers.dart     # Riverpod providers
└── presentation/
    ├── {{screen}}_page.dart        # Page for each screen
    └── widgets/
        └── .gitkeep
```

## Scaffold Process

### Step 1: Create Domain Models

For each entity, create a Freezed model:

```dart
// lib/features/{{name}}/domain/{{entity}}.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{entity}}.freezed.dart';
part '{{entity}}.g.dart';

@freezed
class {{Entity}} with _${{Entity}} {
  const {{Entity}}._();

  const factory {{Entity}}({
    required String id,
    // Add fields based on entity
    required DateTime createdAt,
  }) = _{{Entity}};

  factory {{Entity}}.fromJson(Map<String, dynamic> json) =>
      _${{Entity}}FromJson(json);
}
```

### Step 2: Create DTOs

```dart
// lib/features/{{name}}/data/dtos/{{name}}_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/{{entity}}.dart';

part '{{name}}_dto.freezed.dart';
part '{{name}}_dto.g.dart';

@freezed
class {{Entity}}Dto with _${{Entity}}Dto {
  const {{Entity}}Dto._();

  const factory {{Entity}}Dto({
    required String id,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _{{Entity}}Dto;

  factory {{Entity}}Dto.fromJson(Map<String, dynamic> json) =>
      _${{Entity}}DtoFromJson(json);

  {{Entity}} toDomain() => {{Entity}}(
    id: id,
    createdAt: DateTime.parse(createdAt),
  );
}
```

### Step 3: Create API Client

```dart
// lib/features/{{name}}/data/{{name}}_api.dart
import 'package:dio/dio.dart';
import 'dtos/{{name}}_dto.dart';

class {{Name}}Api {
  final Dio _dio;

  {{Name}}Api(this._dio);

  Future<List<{{Entity}}Dto>> getAll() async {
    final response = await _dio.get('/api/v1/{{name}}');
    return (response.data as List)
        .map((json) => {{Entity}}Dto.fromJson(json))
        .toList();
  }

  Future<{{Entity}}Dto> getById(String id) async {
    final response = await _dio.get('/api/v1/{{name}}/$id');
    return {{Entity}}Dto.fromJson(response.data);
  }

  Future<{{Entity}}Dto> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/{{name}}', data: data);
    return {{Entity}}Dto.fromJson(response.data);
  }
}
```

### Step 4: Create Repository

```dart
// lib/features/{{name}}/data/{{name}}_repository.dart
import 'package:dio/dio.dart';
import 'package:munserv/shared/utils/result.dart';
import '../domain/{{entity}}.dart';
import '{{name}}_api.dart';

abstract class {{Name}}Repository {
  Future<Result<List<{{Entity}}>>> getAll();
  Future<Result<{{Entity}}>> getById(String id);
  Future<Result<{{Entity}}>> create(Create{{Entity}}Request request);
}

class {{Name}}RepositoryImpl implements {{Name}}Repository {
  final {{Name}}Api _api;

  {{Name}}RepositoryImpl(this._api);

  @override
  Future<Result<List<{{Entity}}>>> getAll() async {
    try {
      final dtos = await _api.getAll();
      final entities = dtos.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(e.toString()));
    }
  }

  @override
  Future<Result<{{Entity}}>> getById(String id) async {
    try {
      final dto = await _api.getById(id);
      return Result.success(dto.toDomain());
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(e.toString()));
    }
  }

  @override
  Future<Result<{{Entity}}>> create(Create{{Entity}}Request request) async {
    try {
      final dto = await _api.create(request.toJson());
      return Result.success(dto.toDomain());
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(e.toString()));
    }
  }
}
```

### Step 5: Create Providers

```dart
// lib/features/{{name}}/providers/{{name}}_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:munserv/shared/providers/dio_provider.dart';
import '../data/{{name}}_api.dart';
import '../data/{{name}}_repository.dart';
import '../domain/{{entity}}.dart';

part '{{name}}_providers.g.dart';

@riverpod
{{Name}}Repository {{name}}Repository({{Name}}RepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return {{Name}}RepositoryImpl({{Name}}Api(dio));
}

@riverpod
Future<List<{{Entity}}>> {{name}}List({{Name}}ListRef ref) async {
  final repository = ref.watch({{name}}RepositoryProvider);
  final result = await repository.getAll();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

@riverpod
Future<{{Entity}}?> {{name}}Detail({{Name}}DetailRef ref, String id) async {
  final repository = ref.watch({{name}}RepositoryProvider);
  final result = await repository.getById(id);
  return switch (result) {
    Success(:final data) => data,
    Failure() => null,
  };
}
```

### Step 6: Create Pages

For each screen in `{{screens}}`:

```dart
// lib/features/{{name}}/presentation/{{screen}}_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munserv/shared/widgets/loading_spinner.dart';
import 'package:munserv/shared/widgets/error_display.dart';
import '../providers/{{name}}_providers.dart';

class {{Screen}}Page extends ConsumerWidget {
  const {{Screen}}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    // Provider usage based on screen type

    return Scaffold(
      appBar: AppBar(
        title: const Text('{{Screen}}'),
      ),
      body: Container(
        // Page content
      ),
    );
  }
}
```

### Step 7: Add Routes

Update `lib/routing/app_router.dart`:

```dart
// Add route constant
static const {{name}}List = '/{{name}}';
static const {{name}}Detail = '/{{name}}/:id';

// Add GoRoute
GoRoute(
  path: '/{{name}}',
  builder: (context, state) => const {{Name}}ListPage(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) => {{Name}}DetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
),
```

## Post-Scaffold Commands

```bash
# Generate Freezed/Riverpod code
flutter pub run build_runner build --delete-conflicting-outputs

# Verify no analyzer errors
flutter analyze

# Run tests
flutter test
```

## Output

1. Create all directories in the structure
2. Generate all files with proper imports
3. Run build_runner to generate code
4. Verify with flutter analyze
5. Report created files
