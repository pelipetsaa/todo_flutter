import 'package:equatable/equatable.dart';

import '../../../../domain/error/domain_error.dart';
import '../credential_errors.dart';

part 'register_reducer.dart';

const _unset = Object();

class RegisterState extends Equatable {
  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.isSubmitting = false,
    this.error,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final ValidationError? emailError;
  final ValidationError? passwordError;
  final ValidationError? confirmPasswordError;
  final bool isSubmitting;
  final RegisterError? error;

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    Object? emailError = _unset,
    Object? passwordError = _unset,
    Object? confirmPasswordError = _unset,
    bool? isSubmitting,
    Object? error = _unset,
  }) => RegisterState(
    email: email ?? this.email,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    emailError: identical(emailError, _unset) ? this.emailError : emailError as ValidationError?,
    passwordError: identical(passwordError, _unset) ? this.passwordError : passwordError as ValidationError?,
    confirmPasswordError: identical(confirmPasswordError, _unset)
        ? this.confirmPasswordError
        : confirmPasswordError as ValidationError?,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: identical(error, _unset) ? this.error : error as RegisterError?,
  );

  @override
  List<Object?> get props => [
    email,
    password,
    confirmPassword,
    emailError,
    passwordError,
    confirmPasswordError,
    isSubmitting,
    error,
  ];
}

sealed class RegisterError extends Equatable {
  const RegisterError();

  @override
  List<Object?> get props => const [];
}

final class RegisterEmailTaken extends RegisterError {
  const RegisterEmailTaken();
}

final class RegisterOtherError extends RegisterError {
  const RegisterOtherError(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

sealed class RegisterIntent {
  const RegisterIntent();
}

final class RegisterEmailChanged extends RegisterIntent {
  const RegisterEmailChanged(this.value);

  final String value;
}

final class RegisterPasswordChanged extends RegisterIntent {
  const RegisterPasswordChanged(this.value);

  final String value;
}

final class RegisterConfirmPasswordChanged extends RegisterIntent {
  const RegisterConfirmPasswordChanged(this.value);

  final String value;
}

final class RegisterSubmitClicked extends RegisterIntent {
  const RegisterSubmitClicked();
}

final class RegisterBackClicked extends RegisterIntent {
  const RegisterBackClicked();
}

sealed class RegisterEffect extends Equatable {
  const RegisterEffect();

  @override
  List<Object?> get props => const [];
}

final class RegisterNavigateBack extends RegisterEffect {
  const RegisterNavigateBack();
}

sealed class RegisterMutation {
  const RegisterMutation();

  const factory RegisterMutation.emailChanged(String value) = _EmailChanged;
  const factory RegisterMutation.passwordChanged(String value) = _PasswordChanged;
  const factory RegisterMutation.confirmPasswordChanged(String value) = _ConfirmPasswordChanged;
  const factory RegisterMutation.submitStarted() = _SubmitStarted;
  const factory RegisterMutation.succeeded() = _Succeeded;
  const factory RegisterMutation.failed(DomainError error) = _Failed;
}

final class _EmailChanged extends RegisterMutation {
  const _EmailChanged(this.value);

  final String value;
}

final class _PasswordChanged extends RegisterMutation {
  const _PasswordChanged(this.value);

  final String value;
}

final class _ConfirmPasswordChanged extends RegisterMutation {
  const _ConfirmPasswordChanged(this.value);

  final String value;
}

final class _SubmitStarted extends RegisterMutation {
  const _SubmitStarted();
}

final class _Succeeded extends RegisterMutation {
  const _Succeeded();
}

final class _Failed extends RegisterMutation {
  const _Failed(this.error);

  final DomainError error;
}
