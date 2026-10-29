import '../../../../domain/domain_result.dart';
import '../../../../domain/usecase/auth_use_cases.dart';
import '../../../mvi/mvi_view_model.dart';
import 'register_contract.dart';

class RegisterViewModel extends MviViewModel<RegisterState, RegisterIntent, RegisterEffect> {
  RegisterViewModel(this._register) : super(const RegisterState());

  final RegisterUseCase _register;

  @override
  void onIntent(RegisterIntent intent) {
    switch (intent) {
      case RegisterEmailChanged(:final value):
        _reduce(RegisterMutation.emailChanged(value));
      case RegisterPasswordChanged(:final value):
        _reduce(RegisterMutation.passwordChanged(value));
      case RegisterConfirmPasswordChanged(:final value):
        _reduce(RegisterMutation.confirmPasswordChanged(value));
      case RegisterSubmitClicked():
        _submit();
      case RegisterBackClicked():
        if (!state.isSubmitting) sendEffect(const RegisterNavigateBack());
    }
  }

  Future<void> _submit() async {
    if (state.isSubmitting) return;
    _reduce(const RegisterMutation.submitStarted());
    final result = await _register(state.email, state.password, state.confirmPassword);
    _reduce(switch (result) {
      Success() => const RegisterMutation.succeeded(),
      Failure(:final error) => RegisterMutation.failed(error),
    });
  }

  void _reduce(RegisterMutation mutation) => updateState((state) => RegisterReducer.reduce(state, mutation));
}
