import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../domain/error/domain_error.dart';
import '../../../domain/model/models.dart';

part 'todo_detail_reducer.dart';

const _unset = Object();

class TodoDetailState extends Equatable {
  const TodoDetailState({
    required this.todoId,
    this.title = '',
    this.description = '',
    required this.date,
    required this.time,
    this.status = TodoStatus.todo,
    this.titleError,
    this.descriptionError,
    this.isLoading = false,
    this.loadError,
    this.isSaving = false,
    this.isDeleting = false,
  });

  final String? todoId;
  final String title;
  final String description;

  /// Local calendar date, at midnight.
  final DateTime date;
  final TimeOfDay time;
  final TodoStatus status;
  final ValidationError? titleError;
  final ValidationError? descriptionError;
  final bool isLoading;
  final DomainError? loadError;
  final bool isSaving;
  final bool isDeleting;

  bool get isNew => todoId == null;
  bool get isBusy => isLoading || isSaving || isDeleting;
  bool get canEdit => !isBusy && loadError == null;

  /// The due moment in the device time zone.
  DateTime get dueAt => DateTime(date.year, date.month, date.day, time.hour, time.minute);

  TodoDetailState copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    TodoStatus? status,
    Object? titleError = _unset,
    Object? descriptionError = _unset,
    bool? isLoading,
    Object? loadError = _unset,
    bool? isSaving,
    bool? isDeleting,
  }) => TodoDetailState(
    todoId: todoId,
    title: title ?? this.title,
    description: description ?? this.description,
    date: date ?? this.date,
    time: time ?? this.time,
    status: status ?? this.status,
    titleError: identical(titleError, _unset) ? this.titleError : titleError as ValidationError?,
    descriptionError: identical(descriptionError, _unset)
        ? this.descriptionError
        : descriptionError as ValidationError?,
    isLoading: isLoading ?? this.isLoading,
    loadError: identical(loadError, _unset) ? this.loadError : loadError as DomainError?,
    isSaving: isSaving ?? this.isSaving,
    isDeleting: isDeleting ?? this.isDeleting,
  );

  @override
  List<Object?> get props => [
    todoId,
    title,
    description,
    date,
    time,
    status,
    titleError,
    descriptionError,
    isLoading,
    loadError,
    isSaving,
    isDeleting,
  ];
}

sealed class TodoDetailIntent {
  const TodoDetailIntent();
}

final class TodoDetailRetry extends TodoDetailIntent {
  const TodoDetailRetry();
}

final class TodoDetailTitleChanged extends TodoDetailIntent {
  const TodoDetailTitleChanged(this.value);

  final String value;
}

final class TodoDetailDescriptionChanged extends TodoDetailIntent {
  const TodoDetailDescriptionChanged(this.value);

  final String value;
}

final class TodoDetailStatusSelected extends TodoDetailIntent {
  const TodoDetailStatusSelected(this.status);

  final TodoStatus status;
}

final class TodoDetailDateClicked extends TodoDetailIntent {
  const TodoDetailDateClicked();
}

final class TodoDetailDateSelected extends TodoDetailIntent {
  const TodoDetailDateSelected(this.date);

  final DateTime date;
}

final class TodoDetailTimeClicked extends TodoDetailIntent {
  const TodoDetailTimeClicked();
}

final class TodoDetailTimeSelected extends TodoDetailIntent {
  const TodoDetailTimeSelected(this.time);

  final TimeOfDay time;
}

final class TodoDetailSaveClicked extends TodoDetailIntent {
  const TodoDetailSaveClicked();
}

final class TodoDetailDeleteClicked extends TodoDetailIntent {
  const TodoDetailDeleteClicked();
}

final class TodoDetailDeleteConfirmed extends TodoDetailIntent {
  const TodoDetailDeleteConfirmed();
}

final class TodoDetailBackClicked extends TodoDetailIntent {
  const TodoDetailBackClicked();
}

/// Dialogs are effects: Flutter shows them imperatively and reports the choice back as an intent.
sealed class TodoDetailEffect extends Equatable {
  const TodoDetailEffect();

  @override
  List<Object?> get props => const [];
}

final class TodoDetailClose extends TodoDetailEffect {
  const TodoDetailClose();
}

final class TodoDetailShowError extends TodoDetailEffect {
  const TodoDetailShowError(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class TodoDetailPickDate extends TodoDetailEffect {
  const TodoDetailPickDate(this.initial);

  final DateTime initial;

  @override
  List<Object?> get props => [initial];
}

final class TodoDetailPickTime extends TodoDetailEffect {
  const TodoDetailPickTime(this.initial);

  final TimeOfDay initial;

  @override
  List<Object?> get props => [initial];
}

final class TodoDetailConfirmDelete extends TodoDetailEffect {
  const TodoDetailConfirmDelete();
}

sealed class TodoDetailMutation {
  const TodoDetailMutation();

  const factory TodoDetailMutation.loadStarted() = _LoadStarted;
  const factory TodoDetailMutation.loaded(Todo todo) = _Loaded;
  const factory TodoDetailMutation.loadFailed(DomainError error) = _LoadFailed;
  const factory TodoDetailMutation.titleChanged(String value) = _TitleChanged;
  const factory TodoDetailMutation.descriptionChanged(String value) = _DescriptionChanged;
  const factory TodoDetailMutation.statusSelected(TodoStatus status) = _StatusSelected;
  const factory TodoDetailMutation.dateSelected(DateTime date) = _DateSelected;
  const factory TodoDetailMutation.timeSelected(TimeOfDay time) = _TimeSelected;
  const factory TodoDetailMutation.saveStarted() = _SaveStarted;
  const factory TodoDetailMutation.saveFailed(DomainError error) = _SaveFailed;
  const factory TodoDetailMutation.deleteStarted() = _DeleteStarted;
  const factory TodoDetailMutation.deleteFailed() = _DeleteFailed;
}

final class _LoadStarted extends TodoDetailMutation {
  const _LoadStarted();
}

final class _Loaded extends TodoDetailMutation {
  const _Loaded(this.todo);

  final Todo todo;
}

final class _LoadFailed extends TodoDetailMutation {
  const _LoadFailed(this.error);

  final DomainError error;
}

final class _TitleChanged extends TodoDetailMutation {
  const _TitleChanged(this.value);

  final String value;
}

final class _DescriptionChanged extends TodoDetailMutation {
  const _DescriptionChanged(this.value);

  final String value;
}

final class _StatusSelected extends TodoDetailMutation {
  const _StatusSelected(this.status);

  final TodoStatus status;
}

final class _DateSelected extends TodoDetailMutation {
  const _DateSelected(this.date);

  final DateTime date;
}

final class _TimeSelected extends TodoDetailMutation {
  const _TimeSelected(this.time);

  final TimeOfDay time;
}

final class _SaveStarted extends TodoDetailMutation {
  const _SaveStarted();
}

final class _SaveFailed extends TodoDetailMutation {
  const _SaveFailed(this.error);

  final DomainError error;
}

final class _DeleteStarted extends TodoDetailMutation {
  const _DeleteStarted();
}

final class _DeleteFailed extends TodoDetailMutation {
  const _DeleteFailed();
}
