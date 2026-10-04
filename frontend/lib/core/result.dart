/// Result Pattern implementation according to Week 13 Data Layer architecture.
/// Encapsulates either a successful value [T] or an [Exception].
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(data: final d) => d,
    Failure<T>() => null,
  };

  Exception? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(error: final e) => e,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(Exception error) failure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => success(d),
      Failure<T>(error: final e) => failure(e),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  String toString() => 'Result.Success($data)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.error, [this.stackTrace]);
  final Exception error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'Result.Failure($error)';
}
