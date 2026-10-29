import '../error/domain_error.dart';
import '../model/models.dart';

abstract final class CredentialsValidator {
  static const emailMaxLength = 254;
  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static ValidationError? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return ValidationError.emailBlank;
    if (trimmed.length > emailMaxLength || !_emailRegex.hasMatch(trimmed)) return ValidationError.emailInvalid;
    return null;
  }

  static ValidationError? validateNewPassword(String password) {
    if (password.isEmpty) return ValidationError.passwordBlank;
    if (password.length < passwordMinLength) return ValidationError.passwordTooShort;
    if (password.length > passwordMaxLength) return ValidationError.passwordTooLong;
    return null;
  }

  static List<ValidationError> validateLogin(String email, String password) => [
    ?validateEmail(email),
    if (password.isEmpty) ValidationError.passwordBlank,
  ];

  static List<ValidationError> validateRegistration(String email, String password, String confirmPassword) => [
    ?validateEmail(email),
    ?validateNewPassword(password),
    if (password != confirmPassword) ValidationError.passwordMismatch,
  ];
}

abstract final class TodoValidator {
  static const titleMaxLength = 200;
  static const descriptionMaxLength = 2000;

  static List<ValidationError> validate(TodoDraft draft) {
    final title = draft.title.trim();
    return [
      if (title.isEmpty)
        ValidationError.titleBlank
      else if (title.length > titleMaxLength)
        ValidationError.titleTooLong,
      if (draft.description.length > descriptionMaxLength) ValidationError.descriptionTooLong,
    ];
  }
}
