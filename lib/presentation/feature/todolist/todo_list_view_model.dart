import '../../../domain/domain_result.dart';
import '../../../domain/error/domain_error.dart';
import '../../../domain/usecase/auth_use_cases.dart';
import '../../../domain/usecase/todo_use_cases.dart';
import '../../mvi/mvi_view_model.dart';
import 'todo_list_contract.dart';

class TodoListViewModel extends MviViewModel<TodoListState, TodoListIntent, TodoListEffect> {
  TodoListViewModel(this._getTodosForPeriod, this._logout) : super(const TodoListState());

  final GetTodosForPeriodUseCase _getTodosForPeriod;
  final LogoutUseCase _logout;

  /// Only the latest load may update the state; results of superseded loads are dropped.
  int _loadGeneration = 0;

  @override
  void onIntent(TodoListIntent intent) {
    switch (intent) {
      case TodoListScreenShown() || TodoListRetry():
        _load(pullToRefresh: false);
      case TodoListRefresh():
        _load(pullToRefresh: true);
      case TodoListPeriodSelected(:final period):
        if (period == state.period) return;
        _reduce(TodoListMutation.periodChanged(period));
        _load(pullToRefresh: false);
      case TodoListTodoClicked(:final id):
        sendEffect(TodoListOpenTodo(id));
      case TodoListAddClicked():
        sendEffect(const TodoListOpenTodo(null));
      case TodoListLogoutClicked():
        _logout();
    }
  }

  Future<void> _load({required bool pullToRefresh}) async {
    final generation = ++_loadGeneration;
    final period = state.period;
    _reduce(TodoListMutation.loadStarted(pullToRefresh: pullToRefresh));
    final result = await _getTodosForPeriod(period);
    if (generation != _loadGeneration) return;
    switch (result) {
      case Success(:final value):
        _reduce(TodoListMutation.loaded(period, value));
      case Failure(:final error):
        final hadContent = state.hasLoaded;
        _reduce(TodoListMutation.loadFailed(period, error));
        // An expired session is handled by the auth gate, which navigates to login.
        if (hadContent && error is! UnauthorizedError) sendEffect(TodoListShowError(error));
    }
  }

  void _reduce(TodoListMutation mutation) => updateState((state) => TodoListReducer.reduce(state, mutation));
}
