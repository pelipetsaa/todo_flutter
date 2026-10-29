import 'package:equatable/equatable.dart';

import '../../../../domain/error/domain_error.dart';
import '../credential_errors.dart';

part 'login_reducer.dart';

const _unset = Object();

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.isSubmitting = false,
    this.isGoogleInProgress = false,
    this.error,
  });

  final String email;
  final String password;
  final ValidationError? emailError;
  final ValidationError? passwordError;
  final bool isSubmitting;
  final bool isGoogleInProgress;
  final LoginError? error;

  bool get isBusy => isSubmitting || isGoogleInProgress;

  LoginState copyWith({
    String? email,
    String? password,
    Object? emailError = _unset,
    Object? passwordError = _unset,
    bool? isSubmitting,
    bool? isGoogleInProgress,
    Object? error = _unset,
  }) => LoginState(
    email: email ?? this.email,
    password: password ?? this.password,
    emailError: identical(emailError, _unset) ? this.emailError : emailError as ValidationError?,
    passwordError: identical(passwordError, _unset) ? this.passwordError : passwordError as ValidationError?,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isGoogleInProgress: isGoogleInProgress ?? this.isGoogleInProgress,
    error: identical(error, _unset) ? this.error : error as LoginError?,
  );

  @override
  List<Object?> get props => [email, password, emailError, passwordError, isSubmitting, isGoogleInProgress, error];
}

sealed class LoginError extends Equatable {
  const LoginError();

  @override
  List<Object?> get props => const [];
}

final class LoginInvalidCredentials extends LoginError {
  const LoginInvalidCredentials();
}

final class LoginGoogleError extends LoginError {
  const LoginGoogleError();
}

final class LoginOtherError extends LoginError {
  const LoginOtherError(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

sealed class LoginIntent {
  const LoginIntent();
}

final class LoginEmailChanged extends LoginIntent {
  const LoginEmailChanged(this.value);

  final String value;
}

final class LoginPasswordChanged extends LoginIntent {
  const LoginPasswordChanged(this.value);

  final String value;
}

final class LoginSubmitClicked extends LoginIntent {
  const LoginSubmitClicked();
}

final class LoginGoogleClicked extends LoginIntent {
  const LoginGoogleClicked();
}

final class LoginGoogleTokenReceived extends LoginIntent {
  const LoginGoogleTokenReceived(this.idToken);

  final String idToken;
}

final class LoginGoogleCancelled extends LoginIntent {
  const LoginGoogleCancelled();
}

final class LoginGoogleFailed extends LoginIntent {
  const LoginGoogleFailed(this.message);

  final String? message;
}

final class LoginRegisterClicked extends LoginIntent {
  const LoginRegisterClicked();
}

sealed class LoginEffect extends Equatable {
  const LoginEffect();

  @override
  List<Object?> get props => const [];
}

final class LoginLaunchGoogleSignIn extends LoginEffect {
  const LoginLaunchGoogleSignIn();
}

final class LoginNavigateToRegister extends LoginEffect {
  const LoginNavigateToRegister();
}

/// Results of intents and use cases, folded into [LoginState] by [LoginReducer].
sealed class LoginMutation {
  const LoginMutation();

  const factory LoginMutation.emailChanged(String value) = _EmailChanged;
  const factory LoginMutation.passwordChanged(String value) = _PasswordChanged;
  const factory LoginMutation.submitStarted() = _SubmitStarted;
  const factory LoginMutation.googleStarted() = _GoogleStarted;
  const factory LoginMutation.googleCancelled() = _GoogleCancelled;
  const factory LoginMutation.googleFailed() = _GoogleFailed;
  const factory LoginMutation.succeeded() = _Succeeded;
  const factory LoginMutation.failed(DomainError error, {bool viaGoogle}) = _Failed;
}

final class _EmailChanged extends LoginMutation {
  const _EmailChanged(this.value);

  final String value;
}

final class _PasswordChanged extends LoginMutation {
  const _PasswordChanged(this.value);

  final String value;
}

final class _SubmitStarted extends LoginMutation {
  const _SubmitStarted();
}

final class _GoogleStarted extends LoginMutation {
  const _GoogleStarted();
}

final class _GoogleCancelled extends LoginMutation {
  const _GoogleCancelled();
}

final class _GoogleFailed extends LoginMutation {
  const _GoogleFailed();
}

final class _Succeeded extends LoginMutation {
  const _Succeeded();
}

final class _Failed extends LoginMutation {
  const _Failed(this.error, {this.viaGoogle = false});

  final DomainError error;
  final bool viaGoogle;
}
