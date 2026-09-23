import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/data/services/zalo_sdk_auth.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';
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
  LoginController(
    this._useCase,
    this._repository, [
    this._zalo = const ZaloSdkAuth(),
  ]) : super(LoginIdle());

  final LoginUseCase _useCase;
  final AuthRepository _repository;
  final ZaloSdkAuth _zalo;

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

  Future<void> loginWithZalo() async {
    state = LoginLoading();
    final String zaloToken;
    try {
      // Đi qua trang web Zalo (Chrome Custom Tab): chế độ mở thẳng app Zalo
      // (APP_OR_WEB) bị app Zalo bản mới từ chối với "Bản Zalo hiện tại không tương thích".
      zaloToken = await _zalo.obtainAccessToken(viaWeb: true);
    } on ZaloSdkException catch (e) {
      if (e.cancelled) {
        state = LoginIdle();
        return;
      }
      final hash = kDebugMode ? await _zalo.androidHashKey() : null;
      if (hash != null) debugPrint('ZALO KEY HASH (khai báo trên Zalo Developers): $hash');
      state = LoginError(
        hash == null
            ? e.message
            : '${e.message}\nKey hash cần khai báo trên Zalo Developers: $hash',
      );
      return;
    }
    final result = await _repository.loginWithZalo(zaloAccessToken: zaloToken);
    state = result.failure == null
        ? LoginSuccess()
        : LoginError(result.failure!.message);
  }

  void resetError() {
    if (state is LoginError) state = LoginIdle();
  }
}

final AutoDisposeStateNotifierProvider<LoginController, LoginState>
loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      final repository = ref.read(authRepositoryProvider);
      return LoginController(LoginUseCase(repository), repository);
    });
