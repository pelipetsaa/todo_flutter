import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/presentation/ui/theme.dart';

void main() {
  test('the "To do" badge background stands out from the screen in both themes', () {
    // StatusBadge paints "To do" with surfaceContainerHighest; ColorScheme.light() defaults it to the white surface.
    for (final theme in [TodoTheme.light, TodoTheme.dark]) {
      final colors = theme.colorScheme;
      expect(colors.surfaceContainerHighest, isNot(colors.surface), reason: '${colors.brightness}');
    }
  });
}
