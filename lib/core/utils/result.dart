import 'package:nutri_check/core/errors/failures.dart';

class Result<T> {
  final T? _value;
  final Failure? _failure;

  const Result.success(T value) : _value = value, _failure = null;
  const Result.failure(Failure failure) : _value = null, _failure = failure;

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;

  T get value => _value!;
  Failure get failure => _failure!;

  T? get valueOrNull => _value;
  Failure? get failureOrNull => _failure;

  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(Failure) onFailure,
  }) {
    if (isSuccess) return onSuccess(_value as T);
    return onFailure(_failure!);
  }
}
