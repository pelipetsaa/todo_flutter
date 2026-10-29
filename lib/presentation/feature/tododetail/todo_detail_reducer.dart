part of 'todo_detail_contract.dart';

abstract final class TodoDetailReducer {
  static const _titleErrors = {ValidationError.titleBlank, ValidationError.titleTooLong};

  static TodoDetailState reduce(TodoDetailState state, TodoDetailMutation mutation) => switch (mutation) {
    _LoadStarted() => state.copyWith(isLoading: true, loadError: null),
    _Loaded(:final todo, :final dueAt) => _loaded(state, todo, dueAt),
    _LoadFailed(:final error) => state.copyWith(isLoading: false, loadError: error),
    _TitleChanged(:final value) => state.copyWith(title: value, titleError: null),
    _DescriptionChanged(:final value) => state.copyWith(description: value, descriptionError: null),
    _StatusSelected(:final status) => state.copyWith(status: status),
    _DateSelected(:final date) => state.copyWith(date: DateTime(date.year, date.month, date.day)),
    _TimeSelected(:final time) => state.copyWith(time: time),
    _SaveStarted() => state.copyWith(isSaving: true),
    _SaveFailed(:final error) => _saveFailed(state, error),
    _DeleteStarted() => state.copyWith(isDeleting: true),
    _DeleteFailed() => state.copyWith(isDeleting: false),
  };

  static TodoDetailState _loaded(TodoDetailState state, Todo todo, DateTime dueAt) {
    return state.copyWith(
      title: todo.title,
      description: todo.description,
      date: DateTime(dueAt.year, dueAt.month, dueAt.day),
      time: TimeOfDay(hour: dueAt.hour, minute: dueAt.minute),
      status: todo.status,
      isLoading: false,
      loadError: null,
    );
  }

  static TodoDetailState _saveFailed(TodoDetailState state, DomainError error) {
    final errors = error is ValidationFailure ? error.errors : const <ValidationError>[];
    return state.copyWith(
      isSaving: false,
      titleError: errors.where(_titleErrors.contains).firstOrNull,
      descriptionError: errors.where((e) => e == ValidationError.descriptionTooLong).firstOrNull,
    );
  }
}
