import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/di/app_dependencies.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/domain/repository/repositories.dart';
import 'package:todo_flutter/presentation/auth/google_sign_in_provider.dart';
import 'package:todo_flutter/presentation/navigation/app_navigator.dart';

import '../support/fakes.dart';

class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository(this.session);

  final _changes = StreamController<SessionState>.broadcast();

  @override
  SessionState session;

  @override
  Stream<SessionState> get sessionChanges => _changes.stream;

  void emit(SessionState state) {
    session = state;
    _changes.add(state);
  }
}

void main() {
  late FakeSessionRepository session;
  late FakeTodoRepository todos;

  Future<void> pumpApp(WidgetTester tester, SessionState initial) async {
    session = FakeSessionRepository(initial);
    todos = FakeTodoRepository();
    final dependencies = AppDependencies(
      authRepository: FakeAuthRepository(),
      sessionRepository: session,
      todoRepository: todos,
      googleSignIn: const UnavailableGoogleSignInProvider(),
      clock: () => DateTime(2026, 10, 29, 13),
    );
    await tester.pumpWidget(TodoApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  testWidgets('a stored session opens the todo list', (tester) async {
    await pumpApp(tester, SessionState.loggedIn);
    expect(find.text('My todos'), findsOneWidget);
    expect(todos.ranges, hasLength(1));
  });

  testWidgets('without a session the app opens on sign-in', (tester) async {
    await pumpApp(tester, SessionState.loggedOut);
    expect(find.text('Welcome back! Sign in to see your todos.'), findsOneWidget);
  });

  testWidgets('session changes reset the screen stack', (tester) async {
    await pumpApp(tester, SessionState.loggedOut);
    await tester.tap(find.text('No account yet? Create one'));
    await tester.pumpAndSettle();
    expect(find.text('Use your email and a password with at least 8 characters.'), findsOneWidget);

    session.emit(SessionState.loggedIn);
    await tester.pumpAndSettle();
    expect(find.text('My todos'), findsOneWidget);

    session.emit(SessionState.loggedOut);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back! Sign in to see your todos.'), findsOneWidget);
  });

  testWidgets('the FAB opens a new todo and closing it reloads the list', (tester) async {
    await pumpApp(tester, SessionState.loggedIn);
    await tester.tap(find.byTooltip('Add todo'));
    await tester.pumpAndSettle();
    expect(find.text('New todo'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('My todos'), findsOneWidget);
    expect(todos.ranges, hasLength(2));
  });
}
