import 'package:equatable/equatable.dart';

enum TodoStatus { todo, inProgress, done }

class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final TodoStatus status;

  @override
  List<Object?> get props => [id, title, description, dueAt, status];
}

class TodoDraft extends Equatable {
  const TodoDraft({required this.title, required this.description, required this.dueAt, required this.status});

  final String title;
  final String description;
  final DateTime dueAt;
  final TodoStatus status;

  TodoDraft copyWith({String? title}) =>
      TodoDraft(title: title ?? this.title, description: description, dueAt: dueAt, status: status);

  @override
  List<Object?> get props => [title, description, dueAt, status];
}

enum Period { today, week, month }

/// Half-open interval `[from, to)`.
class TimeRange extends Equatable {
  TimeRange({required this.from, required this.to}) {
    if (!from.isBefore(to)) throw ArgumentError('from must be before to');
  }

  final DateTime from;
  final DateTime to;

  bool contains(DateTime instant) => !instant.isBefore(from) && instant.isBefore(to);

  @override
  List<Object?> get props => [from, to];
}

enum SessionState { loggedIn, loggedOut }
