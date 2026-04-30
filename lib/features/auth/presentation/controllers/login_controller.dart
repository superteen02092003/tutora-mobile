import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/login_usecase.dart';

// State
sealed class LoginState {}

final class LoginIdle extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {}

final class LoginError extends LoginState {
  LoginError(this.message);
  final String message;
}

// Controller
class LoginController extends StateNotifier<LoginState> {
  LoginController(this._useCase) : super(LoginIdle());

  final LoginUseCase _useCase;

  Future<void> login(String emailOrPhone, String password) async {
    state = LoginLoading();
    final result = await _useCase(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    if (result.failure != null) {
      state = LoginError(result.failure!.message);
    } else {
      state = LoginSuccess();
    }
  }

  void resetError() {
    if (state is LoginError) state = LoginIdle();
  }
}

final AutoDisposeStateNotifierProvider<LoginController, LoginState>
loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      return LoginController(
        LoginUseCase(ref.read(authRepositoryProvider)),
      );
    });
