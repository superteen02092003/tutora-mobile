import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/logout_usecase.dart';
import 'package:tutora/shared/services/push_token_service.dart';

sealed class AuthState {}

final class AuthIdle extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthLoggedOut extends AuthState {}

final class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._logoutUseCase, this._pushTokenService)
    : super(AuthIdle());

  final LogoutUseCase _logoutUseCase;
  final PushTokenService _pushTokenService;

  Future<void> logout() async {
    state = AuthLoading();
    try {
      await _pushTokenService.unregisterToken().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    } on Object {
      // Gỡ push token lỗi không được chặn việc đăng xuất.
    }
    final result = await _logoutUseCase();
    if (result.failure != null) {
      state = AuthError(result.failure!.message);
    } else {
      state = AuthLoggedOut();
    }
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      return AuthController(
        LogoutUseCase(ref.read(authRepositoryProvider)),
        ref.read(pushTokenServiceProvider),
      );
    });
