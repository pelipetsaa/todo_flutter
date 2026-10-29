import 'package:flutter/material.dart';

/// A [TextField] driven by state: shows [value] and reports edits through [onChanged],
/// like Compose's `OutlinedTextField(value, onValueChange)`. The controller is kept across
/// rebuilds so that the cursor does not jump.
class SyncedTextField extends StatefulWidget {
  const SyncedTextField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.minLines,
    this.maxLines = 1,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final int? minLines;
  final int? maxLines;

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    enabled: widget.enabled,
    obscureText: widget.obscureText,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    onSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.errorText,
      border: const OutlineInputBorder(),
    ),
  );
}
