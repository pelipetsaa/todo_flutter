import 'package:flutter/material.dart';

class ProgressButton extends StatelessWidget {
  const ProgressButton({
    super.key,
    required this.text,
    required this.inProgress,
    required this.enabled,
    required this.onPressed,
    this.outlined = false,
  });

  final String text;
  final bool inProgress;
  final bool enabled;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = inProgress
        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(text);
    final style = ButtonStyle(minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)));
    final onPressed = enabled ? this.onPressed : null;
    return outlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
