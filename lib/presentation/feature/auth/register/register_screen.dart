import 'dart:async';

import 'package:flutter/material.dart';

import '../../../ui/components/progress_button.dart';
import '../../../ui/strings.dart';
import '../auth_components.dart';
import 'register_contract.dart';
import 'register_view_model.dart';

class RegisterRoute extends StatefulWidget {
  const RegisterRoute({super.key, required this.createViewModel, required this.onNavigateBack});

  final RegisterViewModel Function() createViewModel;
  final VoidCallback onNavigateBack;

  @override
  State<RegisterRoute> createState() => _RegisterRouteState();
}

class _RegisterRouteState extends State<RegisterRoute> {
  late final RegisterViewModel _viewModel;
  late final StreamSubscription<RegisterEffect> _effects;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.createViewModel();
    _effects = _viewModel.effects.listen((effect) {
      switch (effect) {
        case RegisterNavigateBack():
          widget.onNavigateBack();
      }
    });
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
    builder: (context, _) => PopScope(
      // The system back gesture goes through the view model too, so it is ignored while submitting.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _viewModel.onIntent(const RegisterBackClicked());
      },
      child: RegisterScreen(state: _viewModel.state, onIntent: _viewModel.onIntent),
    ),
  );
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.state, required this.onIntent});

  final RegisterState state;
  final ValueChanged<RegisterIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final enabled = !state.isSubmitting;
    final error = state.error;
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: enabled ? () => onIntent(const RegisterBackClicked()) : null)),
      body: AuthLayout(
        children: [
          AuthHeader(title: strings.registerTitle, subtitle: strings.registerSubtitle),
          CredentialField(
            value: state.email,
            onChanged: (value) => onIntent(RegisterEmailChanged(value)),
            label: strings.email,
            error: state.emailError,
            enabled: enabled,
            isPassword: false,
            textInputAction: TextInputAction.next,
          ),
          CredentialField(
            value: state.password,
            onChanged: (value) => onIntent(RegisterPasswordChanged(value)),
            label: strings.password,
            error: state.passwordError,
            enabled: enabled,
            isPassword: true,
            textInputAction: TextInputAction.next,
          ),
          CredentialField(
            value: state.confirmPassword,
            onChanged: (value) => onIntent(RegisterConfirmPasswordChanged(value)),
            label: strings.confirmPassword,
            error: state.confirmPasswordError,
            enabled: enabled,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: () => onIntent(const RegisterSubmitClicked()),
          ),
          if (error != null)
            FormError(switch (error) {
              RegisterEmailTaken() => strings.errorEmailTaken,
              RegisterOtherError(:final error) => strings.error(error),
            }),
          ProgressButton(
            text: strings.createAccount,
            inProgress: state.isSubmitting,
            enabled: enabled,
            onPressed: () => onIntent(const RegisterSubmitClicked()),
          ),
        ],
      ),
    );
  }
}
