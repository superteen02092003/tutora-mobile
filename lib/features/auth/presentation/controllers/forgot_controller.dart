import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/reset_password_usecase.dart';

sealed class ForgotState {}

final class ForgotIdle extends ForgotState {}

final class ForgotLoading extends ForgotState {}

final class ForgotOtpSent extends ForgotState {
  ForgotOtpSent(this.phone);
  final String phone;
}

final class ForgotSuccess extends ForgotState {}

final class ForgotError extends ForgotState {
  ForgotError(this.message);
  final String message;
}

class ForgotController extends StateNotifier<ForgotState> {
  ForgotController(this._forgotUseCase, this._resetUseCase)
    : super(ForgotIdle());

  final ForgotPasswordUseCase _forgotUseCase;
  final ResetPasswordUseCase _resetUseCase;

  Future<void> sendOtp({required String phone}) async {
    state = ForgotLoading();
    final result = await _forgotUseCase(phone: phone);
    if (result.failure != null) {
      state = ForgotError(result.failure!.message);
    } else {
      // Bước OTP / đặt lại mật khẩu phải dùng đúng số đã gửi OTP.
      state = ForgotOtpSent(normalizePhone(phone));
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    state = ForgotLoading();
    final result = await _resetUseCase(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );
    if (result.failure != null) {
      state = ForgotError(result.failure!.message);
    } else {
      state = ForgotSuccess();
    }
  }

  void reset() => state = ForgotIdle();
}

final AutoDisposeStateNotifierProvider<ForgotController, ForgotState>
forgotControllerProvider =
    StateNotifierProvider.autoDispose<ForgotController, ForgotState>((ref) {
      final repo = ref.read(authRepositoryProvider);
      return ForgotController(
        ForgotPasswordUseCase(repo),
        ResetPasswordUseCase(repo),
      );
    });
