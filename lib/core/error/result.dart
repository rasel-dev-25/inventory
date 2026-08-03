import 'failure.dart';

/// The outcome of an operation that can fail: either a success value [Ok]
/// or a [Err] wrapping a [Failure]. Every use case and repository method
/// returns `Result<T>` instead of throwing, so callers are forced to
/// consciously handle failure at the point they'd otherwise forget to
/// (the old codebase's unhandled `Future` rejections and silent snackbar
/// catches are exactly what this replaces).
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Returns the success value, or `null` if this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(value: final v) => v,
    Err<T>() => null,
  };

  /// Returns the failure, or `null` if this is an [Ok].
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(failure: final f) => f,
  };

  /// Transforms the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(value: final v) => Result.ok(transform(v)),
    Err<T>(failure: final f) => Result.err(f),
  };

  /// Chains another `Result`-returning operation, short-circuiting on the
  /// first failure. Use this to compose a pipeline of fallible steps
  /// without nested if-checks.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok<T>(value: final v) => transform(v),
    Err<T>(failure: final f) => Result.err(f),
  };

  /// Collapses both branches into a single value — the standard way to
  /// finally consume a `Result` at a UI boundary.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) => switch (this) {
    Ok<T>(value: final v) => onOk(v),
    Err<T>(failure: final f) => onErr(f),
  };

  /// Returns the success value or [fallback] if this is an [Err].
  T getOrElse(T fallback) => switch (this) {
    Ok<T>(value: final v) => v,
    Err<T>() => fallback,
  };

  /// Returns the success value or throws the wrapped [Failure]. Only use
  /// this at the very edge of a script/test where a thrown error truly is
  /// the right behaviour — never inside a use case or controller.
  T unwrap() => switch (this) {
    Ok<T>(value: final v) => v,
    Err<T>(failure: final f) => throw StateError(f.toString()),
  };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
