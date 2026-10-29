part of 'todo_list_contract.dart';

abstract final class TodoListReducer {
  static TodoListState reduce(TodoListState state, TodoListMutation mutation) => switch (mutation) {
    _PeriodChanged(:final period) => period == state.period ? state : TodoListState(period: period),

    // Reloads of an already shown list stay silent instead of flashing a full-screen spinner.
    _LoadStarted(:final pullToRefresh) => state.copyWith(
      isRefreshing: pullToRefresh,
      isLoading: !pullToRefresh && !state.hasLoaded,
      error: null,
    ),

    _Loaded(:final period, :final todos) =>
      period != state.period
          ? state
          : state.copyWith(
              todos: [...todos]..sort((a, b) => a.dueAt.compareTo(b.dueAt)),
              isLoading: false,
              isRefreshing: false,
              hasLoaded: true,
              error: null,
            ),

    _LoadFailed(:final period, :final error) =>
      period != state.period
          ? state
          : state.copyWith(isLoading: false, isRefreshing: false, error: state.hasLoaded ? null : error),
  };
}
