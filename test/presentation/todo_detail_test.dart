import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/usecase/todo_use_cases.dart';
import 'package:todo_flutter/presentation/feature/tododetail/todo_detail_contract.dart';
import 'package:todo_flutter/presentation/feature/tododetail/todo_detail_view_model.dart';

import '../support/fakes.dart';
import '../support/time_zones.dart';

void main() {
  late FakeTodoRepository repository;
  late List<TodoDetailEffect> effects;
  final now = berlin.instantOf(2026, 10, 29, 13, 20);

  TodoDetailViewModel create(String? id) {
    final viewModel = TodoDetailViewModel(
      todoId: id,
      getTodo: GetTodoUseCase(repository),
      saveTodo: SaveTodoUseCase(repository),
      deleteTodo: DeleteTodoUseCase(repository),
      defaultDueDate: DefaultDueDateUseCase(() => now, berlin),
      timeZone: berlin,
    );
    addTearDown(viewModel.dispose);
    viewModel.effects.listen(effects.add);
    return viewModel;
  }

  setUp(() {
    repository = FakeTodoRepository();
    effects = [];
  });

  group('create mode', () {
    test('starts empty with the next full hour', () {
      final state = create(null).state;
      expect(state.isNew, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.date, DateTime(2026, 10, 29));
      expect(state.time, const TimeOfDay(hour: 14, minute: 0));
    });

    test('saves the entered fields and closes', () async {
      final viewModel = create(null)
        ..onIntent(const TodoDetailTitleChanged('  Buy milk '))
        ..onIntent(const TodoDetailDescriptionChanged('two bottles'))
        ..onIntent(TodoDetailDateSelected(DateTime(2026, 11, 2, 23, 59)))
        ..onIntent(const TodoDetailTimeSelected(TimeOfDay(hour: 9, minute: 30)))
        ..onIntent(const TodoDetailStatusSelected(TodoStatus.inProgress))
        ..onIntent(const TodoDetailSaveClicked());
      expect(viewModel.state.isSaving, isTrue);
      await settle();

      expect(
        repository.created.single,
        TodoDraft(
          title: 'Buy milk',
          description: 'two bottles',
          dueAt: berlin.instantOf(2026, 11, 2, 9, 30),
          status: TodoStatus.inProgress,
        ),
      );
      expect(effects, [const TodoDetailClose()]);
    });

    test('date and time are combined in the user time zone', () async {
      // 9:30 on 2 Nov in Berlin (CET, UTC+1) is 8:30 UTC; before 25 Oct (CEST, UTC+2) it would be 7:30.
      create(null)
        ..onIntent(const TodoDetailTitleChanged('Title'))
        ..onIntent(TodoDetailDateSelected(DateTime(2026, 11, 2)))
        ..onIntent(const TodoDetailTimeSelected(TimeOfDay(hour: 9, minute: 30)))
        ..onIntent(const TodoDetailSaveClicked());
      await settle();
      expect(repository.created.single.dueAt, DateTime.utc(2026, 11, 2, 8, 30));

      create(null)
        ..onIntent(const TodoDetailTitleChanged('Title'))
        ..onIntent(TodoDetailDateSelected(DateTime(2026, 10, 20)))
        ..onIntent(const TodoDetailTimeSelected(TimeOfDay(hour: 9, minute: 30)))
        ..onIntent(const TodoDetailSaveClicked());
      await settle();
      expect(repository.created.last.dueAt, DateTime.utc(2026, 10, 20, 7, 30));
    });

    test('validation errors are shown inline, not in a snackbar', () async {
      final viewModel = create(null)..onIntent(const TodoDetailSaveClicked());
      await settle();
      expect(viewModel.state.titleError, ValidationError.titleBlank);
      expect(viewModel.state.isSaving, isFalse);
      expect(effects, isEmpty);
    });

    test('a server error keeps the form and shows a snackbar', () async {
      repository.saveResult = const Failure(NetworkError());
      final viewModel = create(null)
        ..onIntent(const TodoDetailTitleChanged('Title'))
        ..onIntent(const TodoDetailSaveClicked());
      await settle();
      expect(viewModel.state.title, 'Title');
      expect(effects, [const TodoDetailShowError(NetworkError())]);
    });

    test('there is nothing to delete', () async {
      create(null).onIntent(const TodoDetailDeleteClicked());
      await settle();
      expect(effects, isEmpty);
    });
  });

  group('edit mode', () {
    final existing = todo(
      '5',
      title: 'Call mom',
      dueAt: berlin.instantOf(2026, 10, 30, 18, 15),
      status: TodoStatus.done,
    );

    test('loads the todo into the form', () async {
      repository.todoResult = Success(existing);
      final viewModel = create('5');
      expect(viewModel.state.isLoading, isTrue);
      await settle();
      expect(viewModel.state.title, 'Call mom');
      expect(viewModel.state.date, DateTime(2026, 10, 30));
      expect(viewModel.state.time, const TimeOfDay(hour: 18, minute: 15));
      expect(viewModel.state.status, TodoStatus.done);
    });

    test('a failed load can be retried', () async {
      repository.todoResult = const Failure(NotFoundError());
      final viewModel = create('5');
      await settle();
      expect(viewModel.state.loadError, const NotFoundError());
      expect(viewModel.state.canEdit, isFalse);

      repository.todoResult = Success(existing);
      viewModel.onIntent(const TodoDetailRetry());
      await settle();
      expect(viewModel.state.loadError, isNull);
      expect(viewModel.state.title, 'Call mom');
    });

    test('saving updates the todo', () async {
      repository.todoResult = Success(existing);
      final viewModel = create('5');
      await settle();
      viewModel
        ..onIntent(const TodoDetailTitleChanged('Call dad'))
        ..onIntent(const TodoDetailSaveClicked());
      await settle();
      expect(repository.updated.single.$1, '5');
      expect(repository.updated.single.$2.title, 'Call dad');
    });

    test('delete asks for confirmation, then deletes and closes', () async {
      repository.todoResult = Success(existing);
      final viewModel = create('5');
      await settle();

      viewModel.onIntent(const TodoDetailDeleteClicked());
      await settle();
      expect(effects, [const TodoDetailConfirmDelete()]);
      expect(repository.deleted, isEmpty);

      viewModel.onIntent(const TodoDetailDeleteConfirmed());
      await settle();
      expect(repository.deleted, ['5']);
      expect(effects.last, const TodoDetailClose());
    });

    test('pickers open with the current values', () async {
      repository.todoResult = Success(existing);
      final viewModel = create('5');
      await settle();
      viewModel
        ..onIntent(const TodoDetailDateClicked())
        ..onIntent(const TodoDetailTimeClicked());
      await settle();
      expect(effects, [
        TodoDetailPickDate(DateTime(2026, 10, 30)),
        const TodoDetailPickTime(TimeOfDay(hour: 18, minute: 15)),
      ]);
    });
  });
}
