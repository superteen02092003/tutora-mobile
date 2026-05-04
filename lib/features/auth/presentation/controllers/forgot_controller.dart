import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tutora/features/auth/domain/usecases/forgot_password_usecase.dart';

sealed class ForgotState {}

final class ForgotIdle extends ForgotState {}

final class ForgotLoading extends ForgotState {}

final class ForgotSuccess extends ForgotState {}

final class ForgotError extends ForgotState {
  ForgotError(this.message);
  final String message;
}

class ForgotController extends StateNotifier<ForgotState> {
  ForgotController(this._useCase) : super(ForgotIdle());

  final ForgotPasswordUseCase _useCase;

  Future<void> send({required String email}) async {
    state = ForgotLoading();
    final result = await _useCase(email: email);
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
      return ForgotController(
        ForgotPasswordUseCase(ref.read(authRepositoryProvider)),
      );
    });
