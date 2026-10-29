part of 'login_contract.dart';

abstract final class LoginReducer {
  static LoginState reduce(LoginState state, LoginMutation mutation) => switch (mutation) {
    _EmailChanged(:final value) => state.copyWith(email: value, emailError: null, error: null),
    _PasswordChanged(:final value) => state.copyWith(password: value, passwordError: null, error: null),
    _SubmitStarted() => state.copyWith(isSubmitting: true, error: null),
    _GoogleStarted() => state.copyWith(isGoogleInProgress: true, error: null),
    _GoogleCancelled() => state.copyWith(isGoogleInProgress: false),
    _GoogleFailed() => state.copyWith(isGoogleInProgress: false, error: const LoginGoogleError()),
    _Succeeded() => state.copyWith(isSubmitting: false, isGoogleInProgress: false),
    final _Failed failed => _failed(state.copyWith(isSubmitting: false, isGoogleInProgress: false), failed),
  };

  static LoginState _failed(LoginState state, _Failed mutation) => switch (mutation.error) {
    ValidationFailure(:final errors) when errors.isNotEmpty => state.copyWith(
      emailError: emailErrorFrom(errors),
      passwordError: passwordErrorFrom(errors),
    ),
    UnauthorizedError() => state.copyWith(
      error: mutation.viaGoogle ? const LoginGoogleError() : const LoginInvalidCredentials(),
    ),
    final error => state.copyWith(error: LoginOtherError(error)),
  };
}
