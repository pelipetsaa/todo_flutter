import 'package:flutter/material.dart' show TimeOfDay;

import '../../../domain/domain_result.dart';
import '../../../domain/error/domain_error.dart';
import '../../../domain/model/models.dart';
import '../../../domain/usecase/todo_use_cases.dart';
import '../../mvi/mvi_view_model.dart';
import 'todo_detail_contract.dart';

class TodoDetailViewModel extends MviViewModel<TodoDetailState, TodoDetailIntent, TodoDetailEffect> {
  TodoDetailViewModel({
    required String? todoId,
    required GetTodoUseCase getTodo,
    required SaveTodoUseCase saveTodo,
    required DeleteTodoUseCase deleteTodo,
    required DefaultDueDateUseCase defaultDueDate,
  }) : _getTodo = getTodo,
       _saveTodo = saveTodo,
       _deleteTodo = deleteTodo,
       super(_initialState(todoId, defaultDueDate())) {
    if (todoId != null) _load(todoId);
  }

  final GetTodoUseCase _getTodo;
  final SaveTodoUseCase _saveTodo;
  final DeleteTodoUseCase _deleteTodo;

  @override
  void onIntent(TodoDetailIntent intent) {
    switch (intent) {
      case TodoDetailRetry():
        final id = state.todoId;
        if (id != null) _load(id);
      case TodoDetailTitleChanged(:final value):
        _reduce(TodoDetailMutation.titleChanged(value));
      case TodoDetailDescriptionChanged(:final value):
        _reduce(TodoDetailMutation.descriptionChanged(value));
      case TodoDetailStatusSelected(:final status):
        _reduce(TodoDetailMutation.statusSelected(status));
      case TodoDetailDateClicked():
        if (state.canEdit) sendEffect(TodoDetailPickDate(state.date));
      case TodoDetailDateSelected(:final date):
        _reduce(TodoDetailMutation.dateSelected(date));
      case TodoDetailTimeClicked():
        if (state.canEdit) sendEffect(TodoDetailPickTime(state.time));
      case TodoDetailTimeSelected(:final time):
        _reduce(TodoDetailMutation.timeSelected(time));
      case TodoDetailSaveClicked():
        _save();
      case TodoDetailDeleteClicked():
        if (!state.isNew && state.canEdit) sendEffect(const TodoDetailConfirmDelete());
      case TodoDetailDeleteConfirmed():
        _delete();
      case TodoDetailBackClicked():
        if (!state.isBusy) sendEffect(const TodoDetailClose());
    }
  }

  Future<void> _load(String id) async {
    _reduce(const TodoDetailMutation.loadStarted());
    _reduce(switch (await _getTodo(id)) {
      Success(:final value) => TodoDetailMutation.loaded(value),
      Failure(:final error) => TodoDetailMutation.loadFailed(error),
    });
  }

  Future<void> _save() async {
    final state = this.state;
    if (!state.canEdit) return;
    _reduce(const TodoDetailMutation.saveStarted());
    final draft = TodoDraft(
      title: state.title,
      description: state.description,
      dueAt: state.dueAt,
      status: state.status,
    );
    switch (await _saveTodo(state.todoId, draft)) {
      case Success():
        sendEffect(const TodoDetailClose());
      case Failure(:final error):
        _reduce(TodoDetailMutation.saveFailed(error));
        if (_isReportable(error)) sendEffect(TodoDetailShowError(error));
    }
  }

  Future<void> _delete() async {
    final id = state.todoId;
    if (id == null || state.isBusy) return;
    _reduce(const TodoDetailMutation.deleteStarted());
    switch (await _deleteTodo(id)) {
      case Success():
        sendEffect(const TodoDetailClose());
      case Failure(:final error):
        _reduce(const TodoDetailMutation.deleteFailed());
        if (_isReportable(error)) sendEffect(TodoDetailShowError(error));
    }
  }

  void _reduce(TodoDetailMutation mutation) => updateState((state) => TodoDetailReducer.reduce(state, mutation));

  static TodoDetailState _initialState(String? todoId, DateTime defaultDueAt) {
    final dueAt = defaultDueAt.toLocal();
    return TodoDetailState(
      todoId: todoId,
      date: DateTime(dueAt.year, dueAt.month, dueAt.day),
      time: TimeOfDay(hour: dueAt.hour, minute: dueAt.minute),
      isLoading: todoId != null,
    );
  }

  /// Field errors are shown inline and an expired session is handled by the auth gate.
  static bool _isReportable(DomainError error) =>
      !(error is ValidationFailure && error.errors.isNotEmpty) && error is! UnauthorizedError;
}
