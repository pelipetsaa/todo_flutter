import 'package:equatable/equatable.dart';

import 'error/domain_error.dart';

sealed class DomainResult<T> extends Equatable {
  const DomainResult();
}

final class Success<T> extends DomainResult<T> {
  const Success(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class Failure extends DomainResult<Never> {
  const Failure(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

extension DomainResultX<T> on DomainResult<T> {
  DomainResult<R> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    final Failure failure => failure,
  };
}
