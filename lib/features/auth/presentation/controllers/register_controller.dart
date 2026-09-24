import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/register_tutor_usecase.dart';

sealed class RegisterState {}

final class RegisterIdle extends RegisterState {}

final class RegisterLoading extends RegisterState {}

// Đã tạo tài khoản — backend gửi OTP qua Zalo, cần navigate sang OTP
final class RegisterSuccess extends RegisterState {
  RegisterSuccess(this.phone);
  final String phone;
}

final class RegisterError extends RegisterState {
  RegisterError(this.message);
  final String message;
}

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController(this._useCase) : super(RegisterIdle());

  final RegisterTutorUseCase _useCase;

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    state = RegisterLoading();
    final result = await _useCase(
      fullName: fullName,
      phone: phone,
      password: password,
    );
    if (result.failure != null) {
      state = RegisterError(result.failure!.message);
    } else {
      state = RegisterSuccess(result.data ?? phone);
    }
  }

  void resetError() {
    if (state is RegisterError) state = RegisterIdle();
  }
}

final AutoDisposeStateNotifierProvider<RegisterController, RegisterState>
registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
      return RegisterController(
        RegisterTutorUseCase(ref.read(authRepositoryProvider)),
      );
    });
