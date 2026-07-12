import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/resend_otp_usecase.dart';
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
  OtpController(this._verifyUseCase, this._resendUseCase) : super(OtpIdle());

  final VerifyPhoneUseCase _verifyUseCase;
  final ResendOtpUseCase _resendUseCase;

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
      );
    });
