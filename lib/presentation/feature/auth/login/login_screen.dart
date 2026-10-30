import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth/google_sign_in_provider.dart';
import '../../../ui/components/progress_button.dart';
import '../../../ui/strings.dart';
import '../auth_components.dart';
import 'login_contract.dart';
import 'login_view_model.dart';

/// Wires [LoginViewModel] to [LoginScreen] and handles its effects.
class LoginRoute extends StatefulWidget {
  const LoginRoute({
    super.key,
    required this.createViewModel,
    required this.googleSignIn,
    required this.onNavigateToRegister,
  });

  final LoginViewModel Function() createViewModel;
  final GoogleSignInProvider googleSignIn;
  final VoidCallback onNavigateToRegister;

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  late final LoginViewModel _viewModel;
  late final StreamSubscription<LoginEffect> _effects;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.createViewModel();
    _effects = _viewModel.effects.listen(_onEffect);
  }

  Future<void> _onEffect(LoginEffect effect) async {
    switch (effect) {
      case LoginNavigateToRegister():
        widget.onNavigateToRegister();
      case LoginLaunchGoogleSignIn():
        final result = await widget.googleSignIn.signIn();
        // The UI shows a generic message; the reason goes to the device log (`adb logcat -s flutter`).
        if (result case GoogleSignInFailure(:final message)) debugPrint('Google sign-in failed: $message');
        _viewModel.onIntent(switch (result) {
          GoogleSignInSuccess(:final idToken) => LoginGoogleTokenReceived(idToken),
          GoogleSignInCancelled() => const LoginGoogleCancelled(),
          GoogleSignInFailure(:final message) => LoginGoogleFailed(message),
        });
    }
  }

  @override
  void dispose() {
    _effects.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => LoginScreen(state: _viewModel.state, onIntent: _viewModel.onIntent),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.state, required this.onIntent});

  final LoginState state;
  final ValueChanged<LoginIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final error = state.error;
    return Scaffold(
      body: AuthLayout(
        children: [
          AuthHeader(title: strings.loginTitle, subtitle: strings.loginSubtitle),
          CredentialField(
            value: state.email,
            onChanged: (value) => onIntent(LoginEmailChanged(value)),
            label: strings.email,
            error: state.emailError,
            enabled: !state.isBusy,
            isPassword: false,
            textInputAction: TextInputAction.next,
          ),
          CredentialField(
            value: state.password,
            onChanged: (value) => onIntent(LoginPasswordChanged(value)),
            label: strings.password,
            error: state.passwordError,
            enabled: !state.isBusy,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: () => onIntent(const LoginSubmitClicked()),
          ),
          if (error != null) FormError(_message(strings, error)),
          ProgressButton(
            text: strings.signIn,
            inProgress: state.isSubmitting,
            enabled: !state.isBusy,
            onPressed: () => onIntent(const LoginSubmitClicked()),
          ),
          Row(
            spacing: 12,
            children: [
              const Expanded(child: Divider()),
              Text(strings.or, style: Theme.of(context).textTheme.labelMedium),
              const Expanded(child: Divider()),
            ],
          ),
          ProgressButton(
            text: strings.signInWithGoogle,
            inProgress: state.isGoogleInProgress,
            enabled: !state.isBusy,
            onPressed: () => onIntent(const LoginGoogleClicked()),
            outlined: true,
          ),
          TextButton(
            onPressed: state.isBusy ? null : () => onIntent(const LoginRegisterClicked()),
            child: Text(strings.noAccount),
          ),
        ],
      ),
    );
  }

  static String _message(AppStrings strings, LoginError error) => switch (error) {
    LoginInvalidCredentials() => strings.errorInvalidCredentials,
    LoginGoogleError() => strings.errorGoogleFailed,
    LoginOtherError(:final error) => strings.error(error),
  };
}
