part of 'register_contract.dart';

abstract final class RegisterReducer {
  static RegisterState reduce(RegisterState state, RegisterMutation mutation) => switch (mutation) {
    _EmailChanged(:final value) => state.copyWith(email: value, emailError: null, error: null),
    _PasswordChanged(:final value) => state.copyWith(password: value, passwordError: null, error: null),
    _ConfirmPasswordChanged(:final value) => state.copyWith(
      confirmPassword: value,
      confirmPasswordError: null,
      error: null,
    ),
    _SubmitStarted() => state.copyWith(isSubmitting: true, error: null),
    _Succeeded() => state.copyWith(isSubmitting: false),
    _Failed(:final error) => _failed(state.copyWith(isSubmitting: false), error),
  };

  static RegisterState _failed(RegisterState state, DomainError error) => switch (error) {
    ValidationFailure(:final errors) when errors.isNotEmpty => state.copyWith(
      emailError: emailErrorFrom(errors),
      passwordError: passwordErrorFrom(errors),
      confirmPasswordError: confirmPasswordErrorFrom(errors),
    ),
    ConflictError() => state.copyWith(error: const RegisterEmailTaken()),
    _ => state.copyWith(error: RegisterOtherError(error)),
  };
}
