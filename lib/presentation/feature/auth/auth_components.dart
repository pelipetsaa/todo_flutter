import 'package:flutter/material.dart';

import '../../../domain/error/domain_error.dart';
import '../../ui/components/synced_text_field.dart';
import '../../ui/strings.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: children),
          ),
        ),
      ),
    ),
  );
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class CredentialField extends StatelessWidget {
  const CredentialField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.error,
    required this.enabled,
    required this.isPassword,
    required this.textInputAction,
    this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final ValidationError? error;
  final bool enabled;
  final bool isPassword;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return SyncedTextField(
      value: value,
      onChanged: onChanged,
      label: label,
      errorText: error == null ? null : AppStrings.of(context).validation(error),
      enabled: enabled,
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }
}

class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error));
  }
}
