import 'package:equatable/equatable.dart';

import '../../../domain/error/domain_error.dart';
import '../../../domain/model/models.dart';

part 'todo_list_reducer.dart';

const _unset = Object();

class TodoListState extends Equatable {
  const TodoListState({
    this.period = Period.today,
    this.todos = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasLoaded = false,
    this.error,
  });

  final Period period;
  final List<Todo> todos;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasLoaded;
  final DomainError? error;

  TodoListState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasLoaded,
    Object? error = _unset,
  }) => TodoListState(
    period: period,
    todos: todos ?? this.todos,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    error: identical(error, _unset) ? this.error : error as DomainError?,
  );

  @override
  List<Object?> get props => [period, todos, isLoading, isRefreshing, hasLoaded, error];
}

sealed class TodoListIntent {
  const TodoListIntent();
}

/// Sent every time the screen becomes visible, e.g. after returning from the detail screen.
final class TodoListScreenShown extends TodoListIntent {
  const TodoListScreenShown();
}

final class TodoListRefresh extends TodoListIntent {
  const TodoListRefresh();
}

final class TodoListRetry extends TodoListIntent {
  const TodoListRetry();
}

final class TodoListPeriodSelected extends TodoListIntent {
  const TodoListPeriodSelected(this.period);

  final Period period;
}

final class TodoListTodoClicked extends TodoListIntent {
  const TodoListTodoClicked(this.id);

  final String id;
}

final class TodoListAddClicked extends TodoListIntent {
  const TodoListAddClicked();
}

final class TodoListLogoutClicked extends TodoListIntent {
  const TodoListLogoutClicked();
}

sealed class TodoListEffect extends Equatable {
  const TodoListEffect();
}

/// A null [id] opens the editor for a new todo.
final class TodoListOpenTodo extends TodoListEffect {
  const TodoListOpenTodo(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class TodoListShowError extends TodoListEffect {
  const TodoListShowError(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

sealed class TodoListMutation {
  const TodoListMutation();

  const factory TodoListMutation.periodChanged(Period period) = _PeriodChanged;
  const factory TodoListMutation.loadStarted({required bool pullToRefresh}) = _LoadStarted;
  const factory TodoListMutation.loaded(Period period, List<Todo> todos) = _Loaded;
  const factory TodoListMutation.loadFailed(Period period, DomainError error) = _LoadFailed;
}

final class _PeriodChanged extends TodoListMutation {
  const _PeriodChanged(this.period);

  final Period period;
}

final class _LoadStarted extends TodoListMutation {
  const _LoadStarted({required this.pullToRefresh});

  final bool pullToRefresh;
}

final class _Loaded extends TodoListMutation {
  const _Loaded(this.period, this.todos);

  final Period period;
  final List<Todo> todos;
}

final class _LoadFailed extends TodoListMutation {
  const _LoadFailed(this.period, this.error);

  final Period period;
  final DomainError error;
}
