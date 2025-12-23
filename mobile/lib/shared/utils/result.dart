import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_error.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppError error) = Failure<T>;
}

extension ResultExtension<T> on Result<T> {
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppError error) onFailure,
  }) =>
      switch (this) {
        Success(:final data) => onSuccess(data),
        Failure(:final error) => onFailure(error),
      };
}
