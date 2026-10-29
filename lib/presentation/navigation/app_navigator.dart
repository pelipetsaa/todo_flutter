import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../di/app_dependencies.dart';
import '../../domain/model/models.dart';
import '../feature/auth/login/login_screen.dart';
import '../feature/auth/register/register_screen.dart';
import '../feature/todolist/todo_list_screen.dart';
import '../feature/tododetail/todo_detail_screen.dart';
import '../ui/strings.dart';
import '../ui/theme.dart';

/// The app shell and auth gate: starts on the screen that matches the stored session and resets
/// the back stack whenever the session changes — sign-in, logout or a failed token refresh.
class TodoApp extends StatefulWidget {
  const TodoApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<SessionState> _session;

  AppDependencies get _deps => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _session = _deps.observeSession().listen(
      (session) => _navigatorKey.currentState?.pushAndRemoveUntil(_home(session), (_) => false),
    );
  }

  @override
  void dispose() {
    _session.cancel();
    super.dispose();
  }

  Route<void> _home(SessionState session) => switch (session) {
    SessionState.loggedIn => _todoListRoute(),
    SessionState.loggedOut => _loginRoute(),
  };

  Route<void> _loginRoute() => MaterialPageRoute(
    settings: const RouteSettings(name: '/login'),
    builder: (context) => LoginRoute(
      createViewModel: _deps.loginViewModel,
      googleSignIn: _deps.googleSignIn,
      onNavigateToRegister: () => Navigator.of(context).push(_registerRoute()),
    ),
  );

  Route<void> _registerRoute() => MaterialPageRoute(
    settings: const RouteSettings(name: '/register'),
    builder: (context) =>
        RegisterRoute(createViewModel: _deps.registerViewModel, onNavigateBack: () => Navigator.of(context).pop()),
  );

  Route<void> _todoListRoute() => MaterialPageRoute(
    settings: const RouteSettings(name: '/todos'),
    builder: (context) => TodoListRoute(
      createViewModel: _deps.todoListViewModel,
      onOpenTodo: (id) => Navigator.of(context).push(_todoDetailRoute(id)),
    ),
  );

  /// A null [id] opens the editor for a new todo.
  Route<void> _todoDetailRoute(String? id) => MaterialPageRoute(
    settings: RouteSettings(name: '/todos/${id ?? 'new'}'),
    builder: (context) => TodoDetailRoute(
      createViewModel: () => _deps.todoDetailViewModel(id),
      onClose: () => Navigator.of(context).pop(),
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    onGenerateTitle: (context) => AppStrings.of(context).appName,
    theme: TodoTheme.light,
    darkTheme: TodoTheme.dark,
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    // The only named route is the initial one; every other screen is pushed as a Route object.
    onGenerateRoute: (_) => _home(_deps.observeSession.current),
  );
}
