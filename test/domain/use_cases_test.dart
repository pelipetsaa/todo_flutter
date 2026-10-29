import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/period/period_range_calculator.dart';
import 'package:todo_flutter/domain/usecase/auth_use_cases.dart';
import 'package:todo_flutter/domain/usecase/todo_use_cases.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeTodoRepository todos;

  setUp(() {
    auth = FakeAuthRepository();
    todos = FakeTodoRepository();
  });

  group('auth', () {
    test('login validates before calling the server and trims the email', () async {
      final login = LoginWithEmailUseCase(auth);

      expect(await login('', ''), isA<Failure>());
      expect(auth.calls, isEmpty);

      expect(await login(' user@mail.com ', 'secret'), const Success<void>(null));
      expect(auth.calls, ['login user@mail.com secret']);
    });

    test('register reports validation errors', () async {
      final result = await RegisterUseCase(auth)('user@mail.com', 'password1', 'password2');
      expect(result, const Failure(ValidationFailure(errors: [ValidationError.passwordMismatch])));
      expect(auth.calls, isEmpty);
    });

    test('Google sign-in with a blank token is unauthorized', () async {
      expect(await LoginWithGoogleUseCase(auth)(' '), const Failure(UnauthorizedError()));
      expect(auth.calls, isEmpty);
    });
  });

  group('todos', () {
    test('todos for a period are requested for its range', () async {
      final now = DateTime(2026, 10, 29, 13);
      await GetTodosForPeriodUseCase(todos, const PeriodRangeCalculator(), () => now)(Period.week);
      expect(todos.ranges.single, const PeriodRangeCalculator().rangeFor(Period.week, now));
    });

    test('save creates without an id and updates with one, trimming the title', () async {
      final save = SaveTodoUseCase(todos);
      final draft = TodoDraft(
        title: '  Buy milk ',
        description: '',
        dueAt: DateTime.utc(2026),
        status: TodoStatus.todo,
      );

      await save(null, draft);
      await save('42', draft);

      expect(todos.created.single.title, 'Buy milk');
      expect(todos.updated.single.$1, '42');
      expect(todos.updated.single.$2.title, 'Buy milk');
    });

    test('save does not call the server with an invalid draft', () async {
      final draft = TodoDraft(title: '', description: '', dueAt: DateTime.utc(2026), status: TodoStatus.todo);
      final result = await SaveTodoUseCase(todos)(null, draft);
      expect(result, const Failure(ValidationFailure(errors: [ValidationError.titleBlank])));
      expect(todos.created, isEmpty);
    });

    test('the default due date is the next full hour', () {
      expect(DefaultDueDateUseCase(() => DateTime(2026, 10, 29, 13, 45))(), DateTime(2026, 10, 29, 14));
      expect(DefaultDueDateUseCase(() => DateTime(2026, 12, 31, 23, 1))(), DateTime(2027));
    });
  });
}
