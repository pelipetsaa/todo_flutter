import 'package:flutter/foundation.dart';

import '../data/local/token_storage.dart';
import '../data/remote/apis.dart';
import '../data/remote/http_client_factory.dart';
import '../data/repository/repositories.dart';
import '../data/session/session_manager.dart';
import '../domain/period/period_range_calculator.dart';
import '../domain/repository/repositories.dart';
import '../domain/usecase/auth_use_cases.dart';
import '../domain/usecase/todo_use_cases.dart';
import '../presentation/auth/google_sign_in_provider.dart';
import '../presentation/feature/auth/login/login_view_model.dart';
import '../presentation/feature/auth/register/register_view_model.dart';
import '../presentation/feature/todolist/todo_list_view_model.dart';
import '../presentation/feature/tododetail/todo_detail_view_model.dart';
import 'app_config.dart';

/// Composition root: builds the object graph once and creates a view model for every screen.
class AppDependencies {
  AppDependencies({
    required AuthRepository authRepository,
    required SessionRepository sessionRepository,
    required TodoRepository todoRepository,
    required this.googleSignIn,
    Clock clock = DateTime.now,
  }) : _authRepository = authRepository,
       _todoRepository = todoRepository,
       _clock = clock,
       observeSession = ObserveSessionUseCase(sessionRepository);

  static Future<AppDependencies> create(AppConfig config) async {
    final session = SessionManager(SecureTokenStorage());
    await session.restore();
    final dio = HttpClientFactory.create(ApiConfig(baseUrl: config.apiBaseUrl, enableLogging: kDebugMode), session);
    return AppDependencies(
      authRepository: AuthRepositoryImpl(AuthApi(dio), session),
      sessionRepository: session,
      todoRepository: TodoRepositoryImpl(TodoApi(dio)),
      googleSignIn: config.isGoogleSignInConfigured
          ? PluginGoogleSignInProvider(clientId: config.googleIosClientId, serverClientId: config.googleServerClientId)
          : const UnavailableGoogleSignInProvider(),
    );
  }

  final AuthRepository _authRepository;
  final TodoRepository _todoRepository;
  final Clock _clock;
  final GoogleSignInProvider googleSignIn;
  final ObserveSessionUseCase observeSession;

  LoginViewModel loginViewModel() =>
      LoginViewModel(LoginWithEmailUseCase(_authRepository), LoginWithGoogleUseCase(_authRepository));

  RegisterViewModel registerViewModel() => RegisterViewModel(RegisterUseCase(_authRepository));

  TodoListViewModel todoListViewModel() => TodoListViewModel(
    GetTodosForPeriodUseCase(_todoRepository, const PeriodRangeCalculator(), _clock),
    LogoutUseCase(_authRepository),
  );

  TodoDetailViewModel todoDetailViewModel(String? todoId) => TodoDetailViewModel(
    todoId: todoId,
    getTodo: GetTodoUseCase(_todoRepository),
    saveTodo: SaveTodoUseCase(_todoRepository),
    deleteTodo: DeleteTodoUseCase(_todoRepository),
    defaultDueDate: DefaultDueDateUseCase(_clock),
  );
}
