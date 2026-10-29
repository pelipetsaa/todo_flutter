import '../domain_result.dart';
import '../model/models.dart';

abstract interface class AuthRepository {
  Future<DomainResult<void>> login(String email, String password);
  Future<DomainResult<void>> register(String email, String password);
  Future<DomainResult<void>> loginWithGoogle(String idToken);
  Future<DomainResult<void>> logout();
}

abstract interface class SessionRepository {
  SessionState get session;

  /// Emits only when the state actually changes.
  Stream<SessionState> get sessionChanges;
}

abstract interface class TodoRepository {
  Future<DomainResult<List<Todo>>> getTodos(TimeRange range);
  Future<DomainResult<Todo>> getTodo(String id);
  Future<DomainResult<Todo>> create(TodoDraft draft);
  Future<DomainResult<Todo>> update(String id, TodoDraft draft);
  Future<DomainResult<void>> delete(String id);
}
