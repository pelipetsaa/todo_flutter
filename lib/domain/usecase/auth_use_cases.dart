import '../domain_result.dart';
import '../error/domain_error.dart';
import '../model/models.dart';
import '../repository/repositories.dart';
import '../validation/validators.dart';

class LoginWithEmailUseCase {
  const LoginWithEmailUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<DomainResult<void>> call(String email, String password) async {
    final errors = CredentialsValidator.validateLogin(email, password);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors: errors));
    return _authRepository.login(email.trim(), password);
  }
}

class RegisterUseCase {
  const RegisterUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<DomainResult<void>> call(String email, String password, String confirmPassword) async {
    final errors = CredentialsValidator.validateRegistration(email, password, confirmPassword);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors: errors));
    return _authRepository.register(email.trim(), password);
  }
}

class LoginWithGoogleUseCase {
  const LoginWithGoogleUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<DomainResult<void>> call(String idToken) async {
    if (idToken.trim().isEmpty) return const Failure(UnauthorizedError());
    return _authRepository.loginWithGoogle(idToken);
  }
}

class LogoutUseCase {
  const LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<DomainResult<void>> call() => _authRepository.logout();
}

class ObserveSessionUseCase {
  const ObserveSessionUseCase(this._sessionRepository);

  final SessionRepository _sessionRepository;

  SessionState get current => _sessionRepository.session;

  Stream<SessionState> call() => _sessionRepository.sessionChanges;
}
