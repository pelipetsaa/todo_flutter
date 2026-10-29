import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/period/period_range_calculator.dart';
import 'package:todo_flutter/domain/usecase/auth_use_cases.dart';
import 'package:todo_flutter/domain/usecase/todo_use_cases.dart';
import 'package:todo_flutter/presentation/feature/todolist/todo_list_contract.dart';
import 'package:todo_flutter/presentation/feature/todolist/todo_list_view_model.dart';

import '../support/fakes.dart';

void main() {
  group('TodoListReducer', () {
    test('sorts loaded todos by due date', () {
      final late = todo('late', dueAt: DateTime.utc(2026, 10, 29, 18));
      final early = todo('early', dueAt: DateTime.utc(2026, 10, 29, 9));
      final next = TodoListReducer.reduce(const TodoListState(), TodoListMutation.loaded(Period.today, [late, early]));
      expect(next.todos, [early, late]);
      expect(next.hasLoaded, isTrue);
    });

    test('a full-screen spinner only before the first load', () {
      final first = TodoListReducer.reduce(
        const TodoListState(),
        const TodoListMutation.loadStarted(pullToRefresh: false),
      );
      expect(first.isLoading, isTrue);

      const shown = TodoListState(hasLoaded: true);
      final reload = TodoListReducer.reduce(shown, const TodoListMutation.loadStarted(pullToRefresh: false));
      expect(reload.isLoading, isFalse);
      final pull = TodoListReducer.reduce(shown, const TodoListMutation.loadStarted(pullToRefresh: true));
      expect(pull.isRefreshing, isTrue);
    });

    test('results for another period are ignored', () {
      const state = TodoListState(period: Period.week, isLoading: true);
      expect(TodoListReducer.reduce(state, TodoListMutation.loaded(Period.today, [todo('1')])), state);
      expect(TodoListReducer.reduce(state, const TodoListMutation.loadFailed(Period.today, NetworkError())), state);
    });

    test('a failed reload keeps the shown list', () {
      final state = TodoListState(hasLoaded: true, todos: [todo('1')], isRefreshing: true);
      final next = TodoListReducer.reduce(state, const TodoListMutation.loadFailed(Period.today, NetworkError()));
      expect(next.todos, [todo('1')]);
      expect(next.error, isNull);
      expect(next.isRefreshing, isFalse);
    });

    test('switching the period resets the list', () {
      final state = TodoListState(hasLoaded: true, todos: [todo('1')]);
      expect(
        TodoListReducer.reduce(state, const TodoListMutation.periodChanged(Period.month)),
        const TodoListState(period: Period.month),
      );
    });
  });

  group('TodoListViewModel', () {
    late FakeTodoRepository repository;
    late FakeAuthRepository auth;
    late TodoListViewModel viewModel;
    late List<TodoListEffect> effects;
    final now = DateTime(2026, 10, 29, 13);

    setUp(() {
      repository = FakeTodoRepository();
      auth = FakeAuthRepository();
      viewModel = TodoListViewModel(
        GetTodosForPeriodUseCase(repository, const PeriodRangeCalculator(), () => now),
        LogoutUseCase(auth),
      );
      effects = [];
      viewModel.effects.listen(effects.add);
    });

    tearDown(() => viewModel.dispose());

    test('loads today on first show', () async {
      repository.todosResult = Success([todo('1')]);
      viewModel.onIntent(const TodoListScreenShown());
      expect(viewModel.state.isLoading, isTrue);
      await settle();
      expect(viewModel.state.todos, [todo('1')]);
      expect(repository.ranges.single, const PeriodRangeCalculator().rangeFor(Period.today, now));
    });

    test('an error before anything is shown replaces the list', () async {
      repository.todosResult = const Failure(NetworkError());
      viewModel.onIntent(const TodoListScreenShown());
      await settle();
      expect(viewModel.state.error, const NetworkError());
      expect(effects, isEmpty);
    });

    test('an error on reload keeps the list and shows a snackbar', () async {
      repository.todosResult = Success([todo('1')]);
      viewModel.onIntent(const TodoListScreenShown());
      await settle();

      repository.todosResult = const Failure(NetworkError());
      viewModel.onIntent(const TodoListRefresh());
      await settle();

      expect(viewModel.state.todos, [todo('1')]);
      expect(effects, [const TodoListShowError(NetworkError())]);
    });

    test('an expired session on reload is left to the auth gate', () async {
      repository.todosResult = Success([todo('1')]);
      viewModel.onIntent(const TodoListScreenShown());
      await settle();

      repository.todosResult = const Failure(UnauthorizedError());
      viewModel.onIntent(const TodoListRefresh());
      await settle();
      expect(effects, isEmpty);
    });

    test('selecting a period loads it; a slower earlier load is dropped', () async {
      final slowToday = Completer<DomainResult<List<Todo>>>();
      repository.pendingTodos = slowToday;
      viewModel.onIntent(const TodoListScreenShown());

      repository.todosResult = Success([todo('week')]);
      viewModel.onIntent(const TodoListPeriodSelected(Period.week));
      await settle();
      slowToday.complete(Success([todo('today')]));
      await settle();

      expect(viewModel.state.period, Period.week);
      expect(viewModel.state.todos, [todo('week')]);
    });

    test('selecting a period requests its range', () async {
      viewModel.onIntent(const TodoListScreenShown());
      await settle();
      viewModel.onIntent(const TodoListPeriodSelected(Period.month));
      await settle();
      expect(repository.ranges.last, const PeriodRangeCalculator().rangeFor(Period.month, now));
      expect(viewModel.state.period, Period.month);
    });

    test('reselecting the same period does nothing', () async {
      viewModel.onIntent(const TodoListScreenShown());
      await settle();
      final shown = viewModel.state;
      viewModel.onIntent(const TodoListPeriodSelected(Period.today));
      await settle();
      expect(repository.ranges, hasLength(1));
      expect(viewModel.state, shown);
    });

    test('rows and the FAB open the detail screen', () async {
      viewModel
        ..onIntent(const TodoListTodoClicked('7'))
        ..onIntent(const TodoListAddClicked());
      await settle();
      expect(effects, [const TodoListOpenTodo('7'), const TodoListOpenTodo(null)]);
    });

    test('logout', () async {
      viewModel.onIntent(const TodoListLogoutClicked());
      await settle();
      expect(auth.calls, ['logout']);
    });
  });
}
