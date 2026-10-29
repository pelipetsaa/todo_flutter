import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/data/local/token_storage.dart';
import 'package:todo_flutter/data/remote/apis.dart';
import 'package:todo_flutter/data/remote/http_client_factory.dart';
import 'package:todo_flutter/data/repository/repositories.dart';
import 'package:todo_flutter/data/session/session_manager.dart';
import 'package:todo_flutter/domain/domain_result.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';

import '../support/fakes.dart';

/// Answers requests with [handler] instead of the network and records them.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  List<String> get paths => [for (final r in requests) '${r.method} ${r.uri.path}'];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Each attempt is recorded separately: retries reuse the same options, so the headers are copied.
    requests.add(options.copyWith(headers: Map.of(options.headers)));
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, [Object? body]) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> tokenPair(String suffix) => {
  'accessToken': 'access-$suffix',
  'refreshToken': 'refresh-$suffix',
  'expiresInSeconds': 900,
};

Map<String, dynamic> todoJson(String id, {String dueAt = '2026-10-29T13:00:00Z', String status = 'TODO'}) => {
  'id': id,
  'title': 'Todo $id',
  'description': '',
  'dueAt': dueAt,
  'status': status,
  'createdAt': '2026-10-28T10:00:00.123456Z',
  'updatedAt': '2026-10-28T10:00:00.123456Z',
};

void main() {
  late InMemoryTokenStorage storage;
  late SessionManager session;
  late FakeAdapter adapter;
  late AuthRepositoryImpl auth;
  late TodoRepositoryImpl todos;

  Future<void> build({StoredTokens? tokens}) async {
    storage = InMemoryTokenStorage(tokens);
    session = SessionManager(storage);
    await session.restore();
    adapter = FakeAdapter((_) => jsonResponse(500));
    final dio = HttpClientFactory.create(
      const ApiConfig(baseUrl: 'http://test'),
      session,
      adapter: adapter,
      retryDelay: Duration.zero,
    );
    auth = AuthRepositoryImpl(AuthApi(dio), session);
    todos = TodoRepositoryImpl(TodoApi(dio));
  }

  const loggedIn = StoredTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  final range = TimeRange(from: DateTime.utc(2026, 10, 29), to: DateTime.utc(2026, 10, 30));

  group('auth', () {
    setUp(() => build());

    test('login stores the token pair and starts the session', () async {
      adapter.handler = (_) => jsonResponse(200, tokenPair('1'));
      final changes = <SessionState>[];
      session.sessionChanges.listen(changes.add);

      final result = await auth.login('user@mail.com', 'secret');

      expect(result, const Success<void>(null));
      expect(storage.tokens, loggedIn);
      expect(session.session, SessionState.loggedIn);
      await settle();
      expect(changes, [SessionState.loggedIn]);
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/v1/auth/login');
      expect(request.data, {'email': 'user@mail.com', 'password': 'secret'});
      expect(request.headers['Authorization'], isNull);
    });

    test('wrong credentials map to Unauthorized and keep the user logged out', () async {
      adapter.handler = (_) => jsonResponse(401, {'code': 'UNAUTHORIZED', 'message': 'Invalid credentials'});
      expect(await auth.login('user@mail.com', 'wrong'), const Failure(UnauthorizedError()));
      expect(session.session, SessionState.loggedOut);
    });

    test('register with a taken email is a conflict', () async {
      adapter.handler = (_) => jsonResponse(409, {'code': 'EMAIL_TAKEN', 'message': 'taken'});
      expect(await auth.register('user@mail.com', 'password1'), const Failure(ConflictError()));
    });

    test('Google sign-in sends the ID token', () async {
      adapter.handler = (_) => jsonResponse(200, tokenPair('1'));
      await auth.loginWithGoogle('google-id-token');
      expect(adapter.requests.single.data, {'idToken': 'google-id-token'});
      expect(session.session, SessionState.loggedIn);
    });
  });

  group('logout', () {
    setUp(() => build(tokens: loggedIn));

    test('revokes the refresh token and clears the session', () async {
      adapter.handler = (_) => jsonResponse(204);
      await auth.logout();
      expect(adapter.requests.single.data, {'refreshToken': 'refresh-1'});
      expect(storage.tokens, isNull);
      expect(session.session, SessionState.loggedOut);
    });

    test('clears the session even when the server is unreachable', () async {
      adapter.handler = (options) => throw DioException.connectionError(requestOptions: options, reason: 'offline');
      expect(await auth.logout(), const Success<void>(null));
      expect(session.session, SessionState.loggedOut);
    });
  });

  group('todos', () {
    setUp(() => build(tokens: loggedIn));

    test('requests the range with the access token and maps the response', () async {
      adapter.handler = (_) => jsonResponse(200, [todoJson('1', status: 'IN_PROGRESS'), todoJson('2', status: 'DONE')]);

      final result = await todos.getTodos(range);

      final request = adapter.requests.single;
      expect(request.uri.path, '/api/v1/todos');
      expect(request.uri.queryParameters, {'from': '2026-10-29T00:00:00.000Z', 'to': '2026-10-30T00:00:00.000Z'});
      expect(request.headers['Authorization'], 'Bearer access-1');
      final list = (result as Success<List<Todo>>).value;
      expect(list.map((t) => t.status), [TodoStatus.inProgress, TodoStatus.done]);
      expect(list.first.dueAt, DateTime.utc(2026, 10, 29, 13));
    });

    test('create sends the draft as JSON', () async {
      adapter.handler = (_) => jsonResponse(201, todoJson('9'));
      final draft = TodoDraft(
        title: 'Buy milk',
        description: 'two',
        dueAt: DateTime.utc(2026, 10, 29, 14),
        status: TodoStatus.inProgress,
      );

      final result = await todos.create(draft);

      expect(result, isA<Success<Todo>>());
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {
        'title': 'Buy milk',
        'description': 'two',
        'dueAt': '2026-10-29T14:00:00.000Z',
        'status': 'IN_PROGRESS',
      });
    });

    test('maps HTTP errors to domain errors', () async {
      Future<DomainResult<Todo>> withStatus(int status, [Object? body]) {
        adapter.handler = (_) => jsonResponse(status, body);
        return todos.getTodo('1');
      }

      expect(await withStatus(404, {'code': 'NOT_FOUND', 'message': 'no'}), const Failure(NotFoundError()));
      expect(
        await withStatus(400, {'code': 'VALIDATION_ERROR', 'message': 'bad title'}),
        const Failure(ValidationFailure(serverMessage: 'bad title')),
      );
      expect(await withStatus(429), const Failure(TooManyRequestsError()));
      expect(await withStatus(500, {'code': 'INTERNAL_ERROR', 'message': 'boom'}), const Failure(UnknownError('boom')));
    });

    test('a connection failure is a network error', () async {
      adapter.handler = (options) => throw DioException.connectionError(requestOptions: options, reason: 'offline');
      expect(await todos.getTodos(range), const Failure(NetworkError()));
    });

    test('retries reads on transient proxy errors', () async {
      var calls = 0;
      adapter.handler = (_) => ++calls < 3 ? jsonResponse(503) : jsonResponse(200, []);
      expect(await todos.getTodos(range), const Success<List<Todo>>([]));
      expect(calls, 3);
    });

    test('gives up after two retries', () async {
      adapter.handler = (_) => jsonResponse(502);
      expect(await todos.getTodos(range), isA<Failure>());
      expect(adapter.requests, hasLength(3));
    });

    test('never retries writes', () async {
      adapter.handler = (_) => jsonResponse(503);
      final draft = TodoDraft(title: 't', description: '', dueAt: DateTime.utc(2026), status: TodoStatus.todo);
      expect(await todos.create(draft), isA<Failure>());
      expect(adapter.requests, hasLength(1));
    });
  });

  group('token refresh', () {
    setUp(() => build(tokens: loggedIn));

    test('an expired access token is refreshed and the request repeated', () async {
      adapter.handler = (options) => switch (options.uri.path) {
        '/api/v1/auth/refresh' => jsonResponse(200, tokenPair('2')),
        _ when options.headers['Authorization'] == 'Bearer access-1' => jsonResponse(401),
        _ => jsonResponse(200, [todoJson('1')]),
      };

      final result = await todos.getTodos(range);

      expect(result, isA<Success<List<Todo>>>());
      expect(adapter.paths, ['GET /api/v1/todos', 'POST /api/v1/auth/refresh', 'GET /api/v1/todos']);
      expect(adapter.requests[1].data, {'refreshToken': 'refresh-1'});
      expect(adapter.requests[2].headers['Authorization'], 'Bearer access-2');
      expect(storage.tokens, const StoredTokens(accessToken: 'access-2', refreshToken: 'refresh-2'));
      expect(session.session, SessionState.loggedIn);
    });

    test('a rejected refresh token ends the session', () async {
      adapter.handler = (_) => jsonResponse(401);
      final changes = <SessionState>[];
      session.sessionChanges.listen(changes.add);

      expect(await todos.getTodos(range), const Failure(UnauthorizedError()));

      expect(storage.tokens, isNull);
      await settle();
      expect(changes, [SessionState.loggedOut]);
    });

    test('a refresh without network keeps the session', () async {
      adapter.handler = (options) => options.uri.path == '/api/v1/auth/refresh'
          ? throw DioException.connectionError(requestOptions: options, reason: 'offline')
          : jsonResponse(401);

      expect(await todos.getTodos(range), const Failure(UnauthorizedError()));
      expect(session.session, SessionState.loggedIn);
    });

    test('concurrent requests share one refresh', () async {
      final refreshGate = Completer<void>();
      adapter.handler = (options) async {
        if (options.uri.path == '/api/v1/auth/refresh') {
          await refreshGate.future;
          return jsonResponse(200, tokenPair('2'));
        }
        return options.headers['Authorization'] == 'Bearer access-2'
            ? jsonResponse(200, todoJson('1'))
            : jsonResponse(401);
      };

      final first = todos.getTodo('1');
      final second = todos.getTodo('1');
      await settle();
      refreshGate.complete();

      expect(await first, isA<Success<Todo>>());
      expect(await second, isA<Success<Todo>>());
      expect(adapter.paths.where((p) => p.endsWith('/refresh')), hasLength(1));
    });
  });
}
