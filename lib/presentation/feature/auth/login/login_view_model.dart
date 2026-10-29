import '../../../../domain/domain_result.dart';
import '../../../../domain/usecase/auth_use_cases.dart';
import '../../../mvi/mvi_view_model.dart';
import 'login_contract.dart';

class LoginViewModel extends MviViewModel<LoginState, LoginIntent, LoginEffect> {
  LoginViewModel(this._loginWithEmail, this._loginWithGoogle) : super(const LoginState());

  final LoginWithEmailUseCase _loginWithEmail;
  final LoginWithGoogleUseCase _loginWithGoogle;

  @override
  void onIntent(LoginIntent intent) {
    switch (intent) {
      case LoginEmailChanged(:final value):
        _reduce(LoginMutation.emailChanged(value));
      case LoginPasswordChanged(:final value):
        _reduce(LoginMutation.passwordChanged(value));
      case LoginSubmitClicked():
        _submit();
      case LoginGoogleClicked():
        _startGoogleSignIn();
      case LoginGoogleTokenReceived(:final idToken):
        _completeGoogleSignIn(idToken);
      case LoginGoogleCancelled():
        _reduce(const LoginMutation.googleCancelled());
      case LoginGoogleFailed():
        _reduce(const LoginMutation.googleFailed());
      case LoginRegisterClicked():
        if (!state.isBusy) sendEffect(const LoginNavigateToRegister());
    }
  }

  Future<void> _submit() async {
    if (state.isBusy) return;
    _reduce(const LoginMutation.submitStarted());
    final result = await _loginWithEmail(state.email, state.password);
    _reduce(_toMutation(result, viaGoogle: false));
  }

  void _startGoogleSignIn() {
    if (state.isBusy) return;
    _reduce(const LoginMutation.googleStarted());
    sendEffect(const LoginLaunchGoogleSignIn());
  }

  Future<void> _completeGoogleSignIn(String idToken) async {
    _reduce(_toMutation(await _loginWithGoogle(idToken), viaGoogle: true));
  }

  static LoginMutation _toMutation(DomainResult<void> result, {required bool viaGoogle}) => switch (result) {
    Success() => const LoginMutation.succeeded(),
    Failure(:final error) => LoginMutation.failed(error, viaGoogle: viaGoogle),
  };

  void _reduce(LoginMutation mutation) => updateState((state) => LoginReducer.reduce(state, mutation));
}
