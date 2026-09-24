import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:tutora/features/auth/domain/usecases/verify_phone_usecase.dart';

sealed class OtpState {}

final class OtpIdle extends OtpState {}

final class OtpLoading extends OtpState {}

final class OtpSuccess extends OtpState {}

final class OtpResent extends OtpState {}

final class OtpError extends OtpState {
  OtpError(this.message);
  final String message;
}

class OtpController extends StateNotifier<OtpState> {
  OtpController(
    this._verifyUseCase,
    this._resendUseCase,
    this._resetUseCase,
    this._forgotUseCase,
  ) : super(OtpIdle());

  final VerifyPhoneUseCase _verifyUseCase;
  final ResendOtpUseCase _resendUseCase;
  final ResetPasswordUseCase _resetUseCase;
  final ForgotPasswordUseCase _forgotUseCase;

  /// Quên mật khẩu: OTP + mật khẩu mới → POST /auth/reset-password.
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    state = OtpLoading();
    final result = await _resetUseCase(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );
    state = result.failure == null
        ? OtpSuccess()
        : OtpError(result.failure!.message);
  }

  /// Gửi lại OTP quên mật khẩu (POST /auth/forgot-password), khác với
  /// resend OTP xác minh đăng ký.
  Future<void> resendForgot({required String phone}) async {
    state = OtpLoading();
    final result = await _forgotUseCase(phone: phone);
    state = result.failure == null
        ? OtpResent()
        : OtpError(result.failure!.message);
  }

  Future<void> verify({required String phone, required String otp}) async {
    state = OtpLoading();
    final result = await _verifyUseCase(phone: phone, otp: otp);
    if (result.failure != null) {
      state = OtpError(result.failure!.message);
    } else {
      state = OtpSuccess();
    }
  }

  Future<void> resend({required String phone}) async {
    state = OtpLoading();
    final result = await _resendUseCase(phone: phone);
    if (result.failure != null) {
      state = OtpError(result.failure!.message);
    } else {
      state = OtpResent();
    }
  }

  void reset() => state = OtpIdle();
}

final AutoDisposeStateNotifierProvider<OtpController, OtpState>
otpControllerProvider =
    StateNotifierProvider.autoDispose<OtpController, OtpState>((ref) {
      final repo = ref.read(authRepositoryProvider);
      return OtpController(
        VerifyPhoneUseCase(repo),
        ResendOtpUseCase(repo),
        ResetPasswordUseCase(repo),
        ForgotPasswordUseCase(repo),
      );
    });
