import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/auth/presentation/controllers/forgot_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
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
      backgroundColor: AppColors.cream2,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.cream2,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: AppColors.ink3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quay lại đăng nhập',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppLogo(),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E3CA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: AppColors.oxblood,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Quên mật khẩu?\n',
                            style: AppTextStyles.h2(),
                          ),
                          TextSpan(
                            text: 'Không sao cả.',
                            style: AppTextStyles.serifItalic(
                              color: AppColors.oxblood,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nhập số điện thoại đã đăng ký — Tutora sẽ gửi mã OTP qua Zalo để đặt lại mật khẩu.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink3,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),

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

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.cream,
                        minimumSize: const Size(double.infinity, 52),
                        shape: const StadiumBorder(),
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: isLoading || _phoneCtrl.text.trim().isEmpty
                          ? null
                          : _onSend,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cream,
                              ),
                            )
                          : const Text('Gửi mã OTP'),
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: const StadiumBorder(),
                        side: const BorderSide(
                          color: AppColors.line,
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.ink,
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text('Tôi nhớ ra rồi'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
