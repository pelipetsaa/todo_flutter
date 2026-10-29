import 'dart:async';

import 'package:todo_flutter/data/local/token_storage.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/repository/repositories.dart';

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  StoredTokens? tokens;

  @override
  Future<StoredTokens?> read() async => tokens;

  @override
  Future<void> save(StoredTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

class FakeAuthRepository implements AuthRepository {
  DomainResult<void> result = const Success(null);
  final calls = <String>[];

  @override
  Future<DomainResult<void>> login(String email, String password) async {
    calls.add('login $email $password');
    return result;
  }

  @override
  Future<DomainResult<void>> register(String email, String password) async {
    calls.add('register $email $password');
    return result;
  }

  @override
  Future<DomainResult<void>> loginWithGoogle(String idToken) async {
    calls.add('google $idToken');
    return result;
  }

  @override
  Future<DomainResult<void>> logout() async {
    calls.add('logout');
    return const Success(null);
  }
}

/// Each call either returns the configured result or waits for a [Completer] the test completes.
class FakeTodoRepository implements TodoRepository {
  DomainResult<List<Todo>> todosResult = const Success([]);
  DomainResult<Todo>? todoResult;
  DomainResult<Todo>? saveResult;
  DomainResult<void> deleteResult = const Success(null);
  Completer<DomainResult<List<Todo>>>? pendingTodos;

  final ranges = <TimeRange>[];
  final created = <TodoDraft>[];
  final updated = <(String, TodoDraft)>[];
  final deleted = <String>[];

  @override
  Future<DomainResult<List<Todo>>> getTodos(TimeRange range) async {
    ranges.add(range);
    final pending = pendingTodos;
    if (pending != null) {
      pendingTodos = null;
      return pending.future;
    }
    return todosResult;
  }

  @override
  Future<DomainResult<Todo>> getTodo(String id) async => todoResult!;

  @override
  Future<DomainResult<Todo>> create(TodoDraft draft) async {
    created.add(draft);
    return saveResult ?? Success(todo('new', title: draft.title, dueAt: draft.dueAt));
  }

  @override
  Future<DomainResult<Todo>> update(String id, TodoDraft draft) async {
    updated.add((id, draft));
    return saveResult ?? Success(todo(id, title: draft.title, dueAt: draft.dueAt));
  }

  @override
  Future<DomainResult<void>> delete(String id) async {
    deleted.add(id);
    return deleteResult;
  }
}

Todo todo(String id, {String title = 'Todo', DateTime? dueAt, TodoStatus status = TodoStatus.todo}) =>
    Todo(id: id, title: title, description: '', dueAt: dueAt ?? DateTime.utc(2026, 10, 29, 13), status: status);

/// Lets pending futures and stream events run.
Future<void> settle() => Future<void>.delayed(Duration.zero);
