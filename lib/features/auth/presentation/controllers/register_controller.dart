import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/register_usecase.dart';

sealed class RegisterState {}

final class RegisterIdle extends RegisterState {}

final class RegisterLoading extends RegisterState {}

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

  final RegisterUseCase _useCase;

  Future<void> register({
    required String phone,
    required String password,
    required String fullName,
    required String role,
    String? email,
  }) async {
    state = RegisterLoading();
    final result = await _useCase(
      phone: phone,
      password: password,
      fullName: fullName,
      role: role,
      email: email,
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
        RegisterUseCase(ref.read(authRepositoryProvider)),
      );
    });
