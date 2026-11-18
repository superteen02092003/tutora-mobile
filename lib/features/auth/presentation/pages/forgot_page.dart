import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/auth/presentation/controllers/forgot_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ForgotPage extends ConsumerStatefulWidget {
  const ForgotPage({super.key});

  @override
  ConsumerState<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends ConsumerState<ForgotPage> {
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    await ref
        .read(forgotControllerProvider.notifier)
        .sendOtp(phone: _phoneCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forgotControllerProvider, (_, state) {
      if (!context.mounted) return;
      if (state is ForgotOtpSent) {
        context.go(
          AppRoutes.otp,
          extra: OtpArgs(phone: state.phone, mode: OtpMode.forgotPassword),
        );
      } else if (state is ForgotError) {
        AppToast.show(
          context,
          message: state.message,
          type: AppToastType.error,
        );
        ref.read(forgotControllerProvider.notifier).reset();
      }
    });

    final isLoading = ref.watch(forgotControllerProvider) is ForgotLoading;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTopDeco(
                  onBack: () => context.pop(),
                  hand: 'Không sao cả',
                  title: 'Quên mật khẩu?',
                  lead: const Text(
                    'Nhập số điện thoại đã đăng ký — TopTutor sẽ gửi mã OTP qua Zalo để đặt lại mật khẩu.',
                    style: TextStyle(height: 1.55),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    28,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthInput(
                        label: 'Số điện thoại',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        hint: '09x xxx xxxx',
                        enabled: !isLoading,
                        onSubmitted: (_) {
                          if (_phoneCtrl.text.trim().isNotEmpty) {
                            unawaited(_onSend());
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      CanvasCta(
                        label: 'Gửi mã OTP',
                        onPressed: isLoading || _phoneCtrl.text.trim().isEmpty
                            ? null
                            : _onSend,
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TutorColors.ink3,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),

                      CanvasCta(
                        label: 'Tôi nhớ ra rồi',
                        secondary: true,
                        onPressed: isLoading ? null : () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
