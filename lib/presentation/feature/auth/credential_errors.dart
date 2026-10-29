import '../../../domain/error/domain_error.dart';

const _emailErrors = {ValidationError.emailBlank, ValidationError.emailInvalid};
const _passwordErrors = {
  ValidationError.passwordBlank,
  ValidationError.passwordTooShort,
  ValidationError.passwordTooLong,
};

ValidationError? emailErrorFrom(List<ValidationError> errors) => errors.where(_emailErrors.contains).firstOrNull;

ValidationError? passwordErrorFrom(List<ValidationError> errors) => errors.where(_passwordErrors.contains).firstOrNull;

ValidationError? confirmPasswordErrorFrom(List<ValidationError> errors) =>
    errors.where((e) => e == ValidationError.passwordMismatch).firstOrNull;
