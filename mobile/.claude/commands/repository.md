# Repository Generator

name: "repository"
description: "Generate repository with Result pattern for data access"
parameters:
  - name: "name"
    description: "Repository name in PascalCase (e.g., 'Issue', 'Member', 'Notification')"
    required: true
  - name: "feature"
    description: "Feature folder (e.g., 'issues', 'members', 'auth')"
    required: true

---

You are an expert Flutter developer generating repositories for the MunServ mobile app.

## Task

Generate a repository named `{{name}}Repository` in the `{{feature}}` feature.

## Repository Architecture

```
Repository (Abstract Interface)
       ↓
RepositoryImpl (Implementation)
       ↓
API Client (HTTP calls)
       ↓
DTOs (JSON serialization)
```

## File Structure

```
lib/features/{{feature}}/data/
├── {{snake_case(name)}}_api.dart
├── {{snake_case(name)}}_repository.dart
└── dtos/
    └── {{snake_case(name)}}_dto.dart
```

## API Client

```dart
// lib/features/{{feature}}/data/{{snake_case(name)}}_api.dart
import 'package:dio/dio.dart';
import 'dtos/{{snake_case(name)}}_dto.dart';

class {{name}}Api {
  final Dio _dio;

  {{name}}Api(this._dio);

  /// Fetch all {{name}}s
  Future<List<{{name}}Dto>> getAll({
    int? page,
    int? pageSize,
  }) async {
    final response = await _dio.get(
      '/api/v1/{{plural(snake_case(name))}}',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'size': pageSize,
      },
    );
    return (response.data['content'] as List)
        .map((json) => {{name}}Dto.fromJson(json))
        .toList();
  }

  /// Fetch single {{name}} by ID
  Future<{{name}}Dto> getById(String id) async {
    final response = await _dio.get('/api/v1/{{plural(snake_case(name))}}/$id');
    return {{name}}Dto.fromJson(response.data);
  }

  /// Create new {{name}}
  Future<{{name}}Dto> create(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/v1/{{plural(snake_case(name))}}',
      data: data,
    );
    return {{name}}Dto.fromJson(response.data);
  }

  /// Update existing {{name}}
  Future<{{name}}Dto> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      '/api/v1/{{plural(snake_case(name))}}/$id',
      data: data,
    );
    return {{name}}Dto.fromJson(response.data);
  }

  /// Delete {{name}}
  Future<void> delete(String id) async {
    await _dio.delete('/api/v1/{{plural(snake_case(name))}}/$id');
  }
}
```

## DTO (Data Transfer Object)

```dart
// lib/features/{{feature}}/data/dtos/{{snake_case(name)}}_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/{{snake_case(name)}}.dart';

part '{{snake_case(name)}}_dto.freezed.dart';
part '{{snake_case(name)}}_dto.g.dart';

@freezed
class {{name}}Dto with _${{name}}Dto {
  const {{name}}Dto._();

  const factory {{name}}Dto({
    required String id,
    // Add API response fields with @JsonKey for snake_case mapping
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _{{name}}Dto;

  factory {{name}}Dto.fromJson(Map<String, dynamic> json) =>
      _${{name}}DtoFromJson(json);

  /// Convert to domain model
  {{name}} toDomain() => {{name}}(
    id: id,
    createdAt: DateTime.parse(createdAt),
    updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : null,
  );
}

/// Request DTO for creating {{name}}
@freezed
class Create{{name}}Request with _$Create{{name}}Request {
  const Create{{name}}Request._();

  const factory Create{{name}}Request({
    // Add fields needed for creation
    required String field1,
    String? optionalField,
  }) = _Create{{name}}Request;

  Map<String, dynamic> toJson() => {
    'field1': field1,
    if (optionalField != null) 'optional_field': optionalField,
  };
}
```

## Repository Interface

```dart
// lib/features/{{feature}}/data/{{snake_case(name)}}_repository.dart
import 'package:munserv/shared/utils/result.dart';
import '../domain/{{snake_case(name)}}.dart';

/// Abstract interface for {{name}} data operations
abstract class {{name}}Repository {
  /// Fetch all {{name}}s with optional pagination
  Future<Result<List<{{name}}>>> getAll({int? page, int? pageSize});

  /// Fetch single {{name}} by ID
  Future<Result<{{name}}>> getById(String id);

  /// Create new {{name}}
  Future<Result<{{name}}>> create(Create{{name}}Request request);

  /// Update existing {{name}}
  Future<Result<{{name}}>> update(String id, Update{{name}}Request request);

  /// Delete {{name}}
  Future<Result<void>> delete(String id);
}
```

## Repository Implementation

```dart
// lib/features/{{feature}}/data/{{snake_case(name)}}_repository.dart (continued)
import 'package:dio/dio.dart';
import 'package:munserv/shared/utils/result.dart';
import 'package:munserv/shared/utils/app_error.dart';
import '../domain/{{snake_case(name)}}.dart';
import '{{snake_case(name)}}_api.dart';
import 'dtos/{{snake_case(name)}}_dto.dart';

class {{name}}RepositoryImpl implements {{name}}Repository {
  final {{name}}Api _api;

  {{name}}RepositoryImpl(this._api);

  @override
  Future<Result<List<{{name}}>>> getAll({int? page, int? pageSize}) async {
    try {
      final dtos = await _api.getAll(page: page, pageSize: pageSize);
      final entities = dtos.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e, st) {
      return Result.failure(AppError.unknown(e.toString(), st));
    }
  }

  @override
  Future<Result<{{name}}>> getById(String id) async {
    try {
      final dto = await _api.getById(id);
      return Result.success(dto.toDomain());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Result.failure(AppError.notFound('{{name}} not found'));
      }
      return Result.failure(AppError.fromDio(e));
    } catch (e, st) {
      return Result.failure(AppError.unknown(e.toString(), st));
    }
  }

  @override
  Future<Result<{{name}}>> create(Create{{name}}Request request) async {
    try {
      final dto = await _api.create(request.toJson());
      return Result.success(dto.toDomain());
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return Result.failure(AppError.validation(
          e.response?.data['message'] ?? 'Validation failed',
        ));
      }
      return Result.failure(AppError.fromDio(e));
    } catch (e, st) {
      return Result.failure(AppError.unknown(e.toString(), st));
    }
  }

  @override
  Future<Result<{{name}}>> update(String id, Update{{name}}Request request) async {
    try {
      final dto = await _api.update(id, request.toJson());
      return Result.success(dto.toDomain());
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e, st) {
      return Result.failure(AppError.unknown(e.toString(), st));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _api.delete(id);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e, st) {
      return Result.failure(AppError.unknown(e.toString(), st));
    }
  }
}
```

## Error Mapping Pattern

```dart
// lib/shared/utils/app_error.dart
@freezed
sealed class AppError with _$AppError {
  const factory AppError.network(String message) = NetworkError;
  const factory AppError.notFound(String message) = NotFoundError;
  const factory AppError.unauthorized(String message) = UnauthorizedError;
  const factory AppError.validation(String message) = ValidationError;
  const factory AppError.server(String message) = ServerError;
  const factory AppError.unknown(String message, [StackTrace? stackTrace]) = UnknownError;

  static AppError fromDio(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const AppError.network('Connection timeout'),
      DioExceptionType.connectionError =>
        const AppError.network('No internet connection'),
      DioExceptionType.badResponse => _fromResponse(e.response),
      _ => AppError.unknown(e.message ?? 'Unknown error'),
    };
  }

  static AppError _fromResponse(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final message = response?.data?['message'] ?? 'Server error';

    return switch (statusCode) {
      400 => AppError.validation(message),
      401 => const AppError.unauthorized('Session expired'),
      403 => const AppError.unauthorized('Access denied'),
      404 => AppError.notFound(message),
      >= 500 => AppError.server(message),
      _ => AppError.unknown(message),
    };
  }
}
```

## Provider Registration

```dart
// lib/features/{{feature}}/providers/{{feature}}_providers.dart
@riverpod
{{name}}Repository {{camelCase(name)}}Repository({{name}}RepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return {{name}}RepositoryImpl({{name}}Api(dio));
}
```

## Best Practices

### Do
- [ ] Use abstract interface for testability
- [ ] Return `Result<T>` for all operations
- [ ] Map DioException to domain-specific AppError
- [ ] Handle 404 explicitly for single-entity fetches
- [ ] Use DTOs to isolate API structure from domain

### Don't
- [ ] Don't throw exceptions (return Result.failure)
- [ ] Don't expose DTOs to presentation layer
- [ ] Don't hardcode API paths (use constants)
- [ ] Don't log sensitive data

## Output

1. Create API client file
2. Create DTO file with toDomain() method
3. Create repository interface and implementation
4. Register provider in feature providers
5. Run `flutter pub run build_runner build`
6. Verify with `flutter analyze`
