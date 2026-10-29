// The client's real HTTP stack (Dio, auth interceptor, repositories) against a running ToDoList server, catching
// contract drift that the fake-adapter tests cannot. Skipped unless E2E_BASE_URL points at a server, e.g.
// `E2E_BASE_URL=http://localhost:8080 flutter test test/e2e`.
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/data/remote/apis.dart';
import 'package:todo_flutter/data/remote/http_client_factory.dart';
import 'package:todo_flutter/data/repository/repositories.dart';
import 'package:todo_flutter/data/session/session_manager.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';

import '../support/fakes.dart';

void main() {
  final baseUrl = Platform.environment['E2E_BASE_URL'] ?? '';
  final skip = baseUrl.isEmpty ? 'Set E2E_BASE_URL to run against a server' : false;

  late InMemoryTokenStorage storage;
  late SessionManager session;
  late AuthRepositoryImpl auth;
  late TodoRepositoryImpl todos;
  // A fresh account per run keeps the test independent of whatever the database already holds.
  late String email;
  const password = 'password123';

  setUp(() {
    storage = InMemoryTokenStorage();
    session = SessionManager(storage);
    final dio = HttpClientFactory.create(ApiConfig(baseUrl: baseUrl), session);
    auth = AuthRepositoryImpl(AuthApi(dio), session);
    todos = TodoRepositoryImpl(TodoApi(dio));
    email = 'e2e-flutter-${DateTime.now().microsecondsSinceEpoch}@example.com';
  });

  T success<T>(DomainResult<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => fail('expected success, got $error'),
  };

  DomainError failureOf(DomainResult<Object?> result) => switch (result) {
    Failure(:final error) => error,
    Success(:final value) => fail('expected a failure, got $value'),
  };

  test('sign up, manage todos and sign out', () async {
    success(await auth.register(email, password));
    expect(session.session, SessionState.loggedIn);
    expect(failureOf(await auth.register(email.toUpperCase(), password)), const ConflictError());

    final now = DateTime.now().toUtc();
    final range = TimeRange(from: now.subtract(const Duration(days: 1)), to: now.add(const Duration(days: 1)));
    final draft = TodoDraft(
      title: 'E2E todo',
      description: 'created by end_to_end_test',
      dueAt: now.add(const Duration(hours: 1)),
      status: TodoStatus.inProgress,
    );
    final created = success(await todos.create(draft));
    expect(created.title, 'E2E todo');
    expect(created.status, TodoStatus.inProgress);
    expect(created.dueAt.difference(draft.dueAt).inSeconds, 0);

    final listed = success(await todos.getTodos(range));
    expect(listed.map((t) => t.id), contains(created.id));

    final done = TodoDraft(
      title: 'E2E done',
      description: draft.description,
      dueAt: draft.dueAt,
      status: TodoStatus.done,
    );
    expect(success(await todos.update(created.id, done)).status, TodoStatus.done);
    expect(success(await todos.getTodo(created.id)).title, 'E2E done');

    success(await todos.delete(created.id));
    expect(failureOf(await todos.getTodo(created.id)), const NotFoundError());

    await auth.logout();
    expect(session.session, SessionState.loggedOut);
    expect(storage.tokens, isNull);
    expect(failureOf(await todos.getTodos(range)), const UnauthorizedError());

    expect(failureOf(await auth.login(email, 'wrong-password')), const UnauthorizedError());
    success(await auth.login(email, password));
    expect(storage.tokens, isNotNull);
  }, skip: skip);

  test('server validation errors reach the client', () async {
    // The client validates too, so the request goes straight to the repository.
    final error = failureOf(await auth.register(email, 'short'));
    expect(error, isA<ValidationFailure>());
    expect((error as ValidationFailure).serverMessage, contains('8'));
  }, skip: skip);
}
