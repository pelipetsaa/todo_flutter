import '../../core/dto/dtos.dart';
import '../../domain/domain_result.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/repositories.dart';
import '../mapper/mappers.dart';
import '../remote/apis.dart';
import '../remote/safe_api_call.dart';
import '../session/session_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._api, this._session);

  final AuthApi _api;
  final SessionManager _session;

  @override
  Future<DomainResult<void>> login(String email, String password) =>
      _authenticate(() => _api.login(EmailCredentialsDto(email: email, password: password)));

  @override
  Future<DomainResult<void>> register(String email, String password) =>
      _authenticate(() => _api.register(EmailCredentialsDto(email: email, password: password)));

  @override
  Future<DomainResult<void>> loginWithGoogle(String idToken) => _authenticate(() => _api.loginWithGoogle(idToken));

  @override
  Future<DomainResult<void>> logout() async {
    final refreshToken = _session.currentTokens?.refreshToken;
    if (refreshToken != null) {
      // Best effort: the local session is cleared even if the server cannot be reached.
      await safeApiCall(() => _api.logout(refreshToken));
    }
    await _session.end();
    return const Success(null);
  }

  Future<DomainResult<void>> _authenticate(Future<TokenPairDto> Function() call) async {
    final result = await safeApiCall(call);
    if (result case Success(:final value)) await _session.start(value.toStoredTokens());
    return result.map((_) {});
  }
}

class TodoRepositoryImpl implements TodoRepository {
  const TodoRepositoryImpl(this._api);

  final TodoApi _api;

  @override
  Future<DomainResult<List<Todo>>> getTodos(TimeRange range) =>
      safeApiCall(() async => (await _api.getTodos(range.from, range.to)).map((dto) => dto.toDomain()).toList());

  @override
  Future<DomainResult<Todo>> getTodo(String id) => safeApiCall(() async => (await _api.getTodo(id)).toDomain());

  @override
  Future<DomainResult<Todo>> create(TodoDraft draft) =>
      safeApiCall(() async => (await _api.create(draft.toDto())).toDomain());

  @override
  Future<DomainResult<Todo>> update(String id, TodoDraft draft) =>
      safeApiCall(() async => (await _api.update(id, draft.toDto())).toDomain());

  @override
  Future<DomainResult<void>> delete(String id) => safeApiCall(() => _api.delete(id));
}
