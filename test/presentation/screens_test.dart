import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/domain/error/domain_error.dart';
import 'package:todo_flutter/domain/model/models.dart';
import 'package:todo_flutter/presentation/feature/auth/login/login_contract.dart';
import 'package:todo_flutter/presentation/feature/auth/login/login_screen.dart';
import 'package:todo_flutter/presentation/feature/todolist/todo_list_contract.dart';
import 'package:todo_flutter/presentation/feature/todolist/todo_list_screen.dart';
import 'package:todo_flutter/presentation/ui/strings.dart';

import '../support/fakes.dart';

Widget app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  supportedLocales: AppStrings.supportedLocales,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

void main() {
  group('LoginScreen', () {
    testWidgets('typing and tapping send intents', (tester) async {
      final intents = <LoginIntent>[];
      await tester.pumpWidget(app(LoginScreen(state: const LoginState(), onIntent: intents.add)));

      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'user@mail.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.tap(find.text('No account yet? Create one'));

      expect(intents, [
        isA<LoginEmailChanged>().having((i) => i.value, 'value', 'user@mail.com'),
        isA<LoginSubmitClicked>(),
        isA<LoginRegisterClicked>(),
      ]);
    });

    testWidgets('shows field and form errors', (tester) async {
      const state = LoginState(emailError: ValidationError.emailInvalid, error: LoginInvalidCredentials());
      await tester.pumpWidget(app(LoginScreen(state: state, onIntent: (_) {})));
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('buttons are disabled while signing in', (tester) async {
      final intents = <LoginIntent>[];
      await tester.pumpWidget(app(LoginScreen(state: const LoginState(isSubmitting: true), onIntent: intents.add)));
      await tester.tap(find.text('Continue with Google'));
      expect(intents, isEmpty);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is translated to Russian', (tester) async {
      await tester.pumpWidget(
        app(
          LoginScreen(state: const LoginState(), onIntent: (_) {}),
          locale: const Locale('ru'),
        ),
      );
      expect(find.text('Войти через Google'), findsOneWidget);
    });
  });

  group('TodoListScreen', () {
    Future<void> pump(WidgetTester tester, TodoListState state, [List<TodoListIntent>? intents]) =>
        tester.pumpWidget(app(TodoListScreen(state: state, onIntent: intents?.add ?? (_) {}, onRefresh: () async {})));

    testWidgets('rows show time, date, title and status', (tester) async {
      final dueAt = DateTime(2026, 10, 29, 9, 5);
      final intents = <TodoListIntent>[];
      await pump(
        tester,
        TodoListState(
          hasLoaded: true,
          todos: [todo('1', title: 'Buy milk', dueAt: dueAt, status: TodoStatus.inProgress)],
        ),
        intents,
      );

      expect(find.text('09:05'), findsOneWidget);
      expect(find.text('Thu, 29 Oct 2026'), findsOneWidget);
      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);

      await tester.tap(find.text('Buy milk'));
      expect(intents.single, isA<TodoListTodoClicked>().having((i) => i.id, 'id', '1'));
    });

    testWidgets('empty state names the period', (tester) async {
      await pump(tester, const TodoListState(period: Period.week, hasLoaded: true));
      expect(find.text('Nothing planned for this week'), findsOneWidget);
      expect(find.text('Tap + to add a todo'), findsOneWidget);
    });

    testWidgets('error state offers a retry', (tester) async {
      final intents = <TodoListIntent>[];
      await pump(tester, const TodoListState(error: NetworkError()), intents);
      await tester.tap(find.text('Retry'));
      expect(intents.single, isA<TodoListRetry>());
    });

    testWidgets('tabs, FAB and logout send intents', (tester) async {
      final intents = <TodoListIntent>[];
      await pump(tester, const TodoListState(hasLoaded: true), intents);
      await tester.tap(find.text('This month'));
      await tester.tap(find.byTooltip('Add todo'));
      await tester.tap(find.byTooltip('Log out'));
      expect(intents, [
        isA<TodoListPeriodSelected>().having((i) => i.period, 'period', Period.month),
        isA<TodoListAddClicked>(),
        isA<TodoListLogoutClicked>(),
      ]);
    });
  });
}
