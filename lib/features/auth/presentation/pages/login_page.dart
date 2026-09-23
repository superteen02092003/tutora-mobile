import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/login_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/shared/services/push_token_service.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thông báo khi tài khoản học sinh / phụ huynh đăng nhập vào app gia sư.
const tutorOnlyMessage =
    'Ứng dụng này dành cho gia sư. Vui lòng dùng web tutora.vn.';

final Uri _webUri = Uri.parse('https://tutora.vn');

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(loginControllerProvider.notifier)
        .login(_identifierCtrl.text, _passCtrl.text);
  }

  Future<void> _openWeb() async {
    final ok = await launchUrl(_webUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppToast.show(
        context,
        message: 'Không mở được tutora.vn.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _navigateByRole() async {
    final token = await ref.read(secureStorageProvider).getAccessToken();
    if (!mounted || token == null) return;
    final claims = parseJwt(token);
    if (!mounted || claims == null) return;

    // App chỉ dành cho gia sư: học sinh / phụ huynh bị đăng xuất ngay, ở lại
    // trang đăng nhập. Push token chỉ đăng ký sau khi qua bước này.
    if (claims.role != UserRole.tutor) {
      await ref.read(secureStorageProvider).clearTokens();
      if (!mounted) return;
      AppToast.show(
        context,
        message: tutorOnlyMessage,
        type: AppToastType.warning,
        duration: const Duration(seconds: 6),
      );
      return;
    }

    unawaited(ref.read(pushTokenServiceProvider).registerToken());
    context.go(AppRoutes.tutorHome);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (_, state) {
      if (!context.mounted) return;
      if (state is LoginSuccess) {
        unawaited(_navigateByRole());
      } else if (state is LoginRequiresOtp) {
        context.go(
          AppRoutes.otp,
          extra: OtpArgs(phone: state.phone, mode: OtpMode.register),
        );
      } else if (state is LoginError) {
        AppToast.show(
          context,
          message: state.message,
          type: AppToastType.error,
        );
        ref.read(loginControllerProvider.notifier).resetError();
      }
    });

    final state = ref.watch(loginControllerProvider);
    final isLoading = state is LoginLoading;

    return Scaffold(
      body: Column(
        children: [
          const AuthTopDeco(
            bgColor: AppColors.oxblood,
            line1: 'Học tốt hơn,',
            italicWord: 'linh hoạt',
            line2Suffix: 'thời gian',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đăng nhập', style: AppTextStyles.h2()),
                    const SizedBox(height: 4),
                    Text(
                      'Chào mừng trở lại — hãy tiếp tục học.',
                      style: AppTextStyles.serifItalic(color: AppColors.ink3),
                    ),
                    const SizedBox(height: 28),

                    AuthInput(
                      label: 'Số điện thoại, email hoặc tên đăng nhập',
                      controller: _identifierCtrl,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      hint: '090..., email@example.com hoặc tên đăng nhập',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),

                    AuthInput(
                      label: 'Mật khẩu',
                      controller: _passCtrl,
                      obscureText: true,
                      hint: 'Nhập mật khẩu',
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      onSubmitted: (_) => _submit(),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(AppRoutes.forgot),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'Quên mật khẩu?',
                          style: AppTextStyles.serifItalic(
                            color: AppColors.oxblood,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

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
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cream,
                              ),
                            )
                          : const Text('Đăng nhập'),
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                          children: [
                            const TextSpan(text: 'Chưa có tài khoản gia sư? '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () => unawaited(_openWeb()),
                                child: Text(
                                  'Đăng ký trên tutora.vn',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.oxblood,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
