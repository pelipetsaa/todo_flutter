import 'package:equatable/equatable.dart';

sealed class DomainError extends Equatable {
  const DomainError();

  @override
  List<Object?> get props => const [];
}

final class NetworkError extends DomainError {
  const NetworkError();
}

final class UnauthorizedError extends DomainError {
  const UnauthorizedError();
}

final class NotFoundError extends DomainError {
  const NotFoundError();
}

/// The resource conflicts with an existing one, e.g. the email is already registered.
final class ConflictError extends DomainError {
  const ConflictError();
}

/// The server throttled the client, e.g. after too many sign-in attempts.
final class TooManyRequestsError extends DomainError {
  const TooManyRequestsError();
}

final class ValidationFailure extends DomainError {
  const ValidationFailure({this.errors = const [], this.serverMessage});

  final List<ValidationError> errors;
  final String? serverMessage;

  @override
  List<Object?> get props => [errors, serverMessage];
}

final class UnknownError extends DomainError {
  const UnknownError([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

enum ValidationError {
  emailBlank,
  emailInvalid,
  passwordBlank,
  passwordTooShort,
  passwordTooLong,
  passwordMismatch,
  titleBlank,
  titleTooLong,
  descriptionTooLong,
}
