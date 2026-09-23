import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/login_usecase.dart';

sealed class LoginState {}

final class LoginIdle extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {}

// Phone chưa verify — cần navigate sang OTP
final class LoginRequiresOtp extends LoginState {
  LoginRequiresOtp(this.phone);
  final String phone;
}

final class LoginError extends LoginState {
  LoginError(this.message);
  final String message;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._useCase) : super(LoginIdle());

  final LoginUseCase _useCase;

  Future<void> login(String emailOrPhone, String password) async {
    state = LoginLoading();
    final result = await _useCase(
      emailOrPhone: emailOrPhone,
      password: password,
    );
    if (result.failure case final PhoneVerificationRequiredFailure f) {
      state = LoginRequiresOtp(f.phone);
    } else if (result.failure != null) {
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
      final repository = ref.read(authRepositoryProvider);
      return LoginController(LoginUseCase(repository));
    });
