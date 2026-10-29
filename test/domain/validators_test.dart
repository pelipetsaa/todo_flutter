import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/validation/validators.dart';

void main() {
  group('CredentialsValidator', () {
    test('email', () {
      expect(CredentialsValidator.validateEmail('  '), ValidationError.emailBlank);
      expect(CredentialsValidator.validateEmail('user@'), ValidationError.emailInvalid);
      expect(CredentialsValidator.validateEmail('us er@mail.com'), ValidationError.emailInvalid);
      expect(CredentialsValidator.validateEmail('${'a' * 250}@b.co'), ValidationError.emailInvalid);
      expect(CredentialsValidator.validateEmail(' user@mail.com '), isNull);
    });

    test('new password', () {
      expect(CredentialsValidator.validateNewPassword(''), ValidationError.passwordBlank);
      expect(CredentialsValidator.validateNewPassword('1234567'), ValidationError.passwordTooShort);
      expect(CredentialsValidator.validateNewPassword('a' * 129), ValidationError.passwordTooLong);
      expect(CredentialsValidator.validateNewPassword('12345678'), isNull);
    });

    test('login accepts any non-empty password', () {
      expect(CredentialsValidator.validateLogin('user@mail.com', 'x'), isEmpty);
      expect(CredentialsValidator.validateLogin('', ''), [ValidationError.emailBlank, ValidationError.passwordBlank]);
    });

    test('registration reports every problem', () {
      expect(CredentialsValidator.validateRegistration('bad', 'short', 'other'), [
        ValidationError.emailInvalid,
        ValidationError.passwordTooShort,
        ValidationError.passwordMismatch,
      ]);
      expect(CredentialsValidator.validateRegistration('user@mail.com', 'password1', 'password1'), isEmpty);
    });
  });

  group('TodoValidator', () {
    TodoDraft draft({String title = 'Title', String description = ''}) =>
        TodoDraft(title: title, description: description, dueAt: DateTime.utc(2026), status: TodoStatus.todo);

    test('title is trimmed before checking', () {
      expect(TodoValidator.validate(draft(title: '   ')), [ValidationError.titleBlank]);
      expect(TodoValidator.validate(draft(title: ' ${'a' * 200} ')), isEmpty);
      expect(TodoValidator.validate(draft(title: 'a' * 201)), [ValidationError.titleTooLong]);
    });

    test('description length', () {
      expect(TodoValidator.validate(draft(description: 'a' * 2000)), isEmpty);
      expect(TodoValidator.validate(draft(description: 'a' * 2001)), [ValidationError.descriptionTooLong]);
    });
  });
}
