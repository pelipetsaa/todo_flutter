import 'package:flutter/material.dart';

import '../../../domain/model/models.dart';
import '../strings.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TodoStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (container, content) = switch (status) {
      TodoStatus.todo => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
      TodoStatus.inProgress => (colors.primaryContainer, colors.onPrimaryContainer),
      TodoStatus.done => (colors.tertiaryContainer, colors.onTertiaryContainer),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(color: container, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          AppStrings.of(context).status(status),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: content),
        ),
      ),
    );
  }
}
