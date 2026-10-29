import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/usecase/auth_use_cases.dart';
import 'package:todo_flutter/presentation/feature/auth/login/login_contract.dart';
import 'package:todo_flutter/presentation/feature/auth/login/login_view_model.dart';
import 'package:todo_flutter/presentation/feature/auth/register/register_contract.dart';
import 'package:todo_flutter/presentation/feature/auth/register/register_view_model.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('LoginReducer', () {
    test('editing a field clears its error and the form error', () {
      const state = LoginState(emailError: ValidationError.emailBlank, error: LoginInvalidCredentials());
      final next = LoginReducer.reduce(state, const LoginMutation.emailChanged('a'));
      expect(next, const LoginState(email: 'a'));
    });

    test('Unauthorized means wrong credentials, or a failed Google sign-in', () {
      const busy = LoginState(isSubmitting: true);
      expect(
        LoginReducer.reduce(busy, const LoginMutation.failed(UnauthorizedError())).error,
        const LoginInvalidCredentials(),
      );
      expect(
        LoginReducer.reduce(busy, const LoginMutation.failed(UnauthorizedError(), viaGoogle: true)).error,
        const LoginGoogleError(),
      );
    });

    test('other errors are shown as they are', () {
      final next = LoginReducer.reduce(const LoginState(), const LoginMutation.failed(NetworkError()));
      expect(next.error, const LoginOtherError(NetworkError()));
    });
  });

  group('LoginViewModel', () {
    late LoginViewModel viewModel;
    late List<LoginEffect> effects;

    setUp(() {
      viewModel = LoginViewModel(LoginWithEmailUseCase(auth), LoginWithGoogleUseCase(auth));
      effects = [];
      viewModel.effects.listen(effects.add);
    });

    tearDown(() => viewModel.dispose());

    test('invalid input shows field errors without calling the server', () async {
      viewModel.onIntent(const LoginSubmitClicked());
      await settle();
      expect(viewModel.state.emailError, ValidationError.emailBlank);
      expect(viewModel.state.passwordError, ValidationError.passwordBlank);
      expect(viewModel.state.isSubmitting, isFalse);
      expect(auth.calls, isEmpty);
    });

    test('submits the entered credentials', () async {
      viewModel
        ..onIntent(const LoginEmailChanged('user@mail.com'))
        ..onIntent(const LoginPasswordChanged('secret'))
        ..onIntent(const LoginSubmitClicked());
      expect(viewModel.state.isSubmitting, isTrue);
      await settle();
      expect(auth.calls, ['login user@mail.com secret']);
      expect(viewModel.state.isSubmitting, isFalse);
      expect(viewModel.state.error, isNull);
    });

    test('wrong credentials show a form error', () async {
      auth.result = const Failure(UnauthorizedError());
      viewModel
        ..onIntent(const LoginEmailChanged('user@mail.com'))
        ..onIntent(const LoginPasswordChanged('wrong'))
        ..onIntent(const LoginSubmitClicked());
      await settle();
      expect(viewModel.state.error, const LoginInvalidCredentials());
    });

    test('Google sign-in launches the picker and sends the token', () async {
      viewModel.onIntent(const LoginGoogleClicked());
      await settle();
      expect(effects, [const LoginLaunchGoogleSignIn()]);
      expect(viewModel.state.isGoogleInProgress, isTrue);

      viewModel.onIntent(const LoginGoogleTokenReceived('token'));
      await settle();
      expect(auth.calls, ['google token']);
      expect(viewModel.state.isGoogleInProgress, isFalse);
    });

    test('a cancelled Google sign-in is silent, a failed one shows an error', () async {
      viewModel
        ..onIntent(const LoginGoogleClicked())
        ..onIntent(const LoginGoogleCancelled());
      expect(viewModel.state, const LoginState());

      viewModel
        ..onIntent(const LoginGoogleClicked())
        ..onIntent(const LoginGoogleFailed('no account'));
      expect(viewModel.state.error, const LoginGoogleError());
    });

    test('register navigation is ignored while busy', () async {
      viewModel
        ..onIntent(const LoginGoogleClicked())
        ..onIntent(const LoginRegisterClicked());
      await settle();
      expect(effects, [const LoginLaunchGoogleSignIn()]);
    });
  });

  group('RegisterViewModel', () {
    late RegisterViewModel viewModel;
    late List<RegisterEffect> effects;

    setUp(() {
      viewModel = RegisterViewModel(RegisterUseCase(auth));
      effects = [];
      viewModel.effects.listen(effects.add);
    });

    tearDown(() => viewModel.dispose());

    void fill(String email, String password, String confirm) => viewModel
      ..onIntent(RegisterEmailChanged(email))
      ..onIntent(RegisterPasswordChanged(password))
      ..onIntent(RegisterConfirmPasswordChanged(confirm));

    test('maps validation errors to their fields', () async {
      fill('bad', 'short', 'other');
      viewModel.onIntent(const RegisterSubmitClicked());
      await settle();
      expect(viewModel.state.emailError, ValidationError.emailInvalid);
      expect(viewModel.state.passwordError, ValidationError.passwordTooShort);
      expect(viewModel.state.confirmPasswordError, ValidationError.passwordMismatch);
      expect(auth.calls, isEmpty);
    });

    test('a taken email is reported', () async {
      auth.result = const Failure(ConflictError());
      fill('user@mail.com', 'password1', 'password1');
      viewModel.onIntent(const RegisterSubmitClicked());
      await settle();
      expect(auth.calls, ['register user@mail.com password1']);
      expect(viewModel.state.error, const RegisterEmailTaken());
    });

    test('back navigates unless submitting', () async {
      viewModel.onIntent(const RegisterBackClicked());
      await settle();
      expect(effects, [const RegisterNavigateBack()]);
    });
  });
}
