import 'package:flutter/material.dart';

// The same palette as `core/ui/theme/Theme.kt` in ToDoList.
const _lightColors = ColorScheme.light(
  primary: Color(0xFF3F51B5),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFDDE1FF),
  onPrimaryContainer: Color(0xFF001257),
  secondary: Color(0xFF5B5D72),
  secondaryContainer: Color(0xFFE0E0F9),
  tertiary: Color(0xFF00897B),
  tertiaryContainer: Color(0xFFB2DFDB),
  onTertiaryContainer: Color(0xFF00201C),
);

const _darkColors = ColorScheme.dark(
  primary: Color(0xFFB9C3FF),
  onPrimary: Color(0xFF08218A),
  primaryContainer: Color(0xFF2A3BA1),
  onPrimaryContainer: Color(0xFFDDE1FF),
  secondary: Color(0xFFC4C5DD),
  secondaryContainer: Color(0xFF434659),
  tertiary: Color(0xFF80CBC4),
  tertiaryContainer: Color(0xFF00504A),
  onTertiaryContainer: Color(0xFFB2DFDB),
);

abstract final class TodoTheme {
  static final light = ThemeData(colorScheme: _lightColors);
  static final dark = ThemeData(colorScheme: _darkColors);
}
