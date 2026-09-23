import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/login_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/shared/services/push_token_service.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

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

  Future<void> _loginWithZalo() async {
    await ref.read(loginControllerProvider.notifier).loginWithZalo();
  }

  Future<void> _navigateByRole() async {
    final token = await ref.read(secureStorageProvider).getAccessToken();
    if (!mounted || token == null) return;
    final claims = parseJwt(token);
    if (!mounted || claims == null) return;

    unawaited(ref.read(pushTokenServiceProvider).registerToken());

    switch (claims.role) {
      case UserRole.student:
        context.go(AppRoutes.studentHome);
      case UserRole.tutor:
        context.go(AppRoutes.tutorHome);
      case UserRole.parent:
        context.go(AppRoutes.parentHome);
      case UserRole.unknown:
        break;
    }
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

                    _Divider(),

                    _ZaloButton(onPressed: isLoading ? null : _loginWithZalo),

                    const SizedBox(height: 10),

                    _GoogleButton(),

                    const SizedBox(height: 32),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                          children: [
                            const TextSpan(text: 'Chưa có tài khoản? '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () => context.push(AppRoutes.register),
                                child: Text(
                                  'Đăng ký ngay',
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

// ── Internal helpers ───────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'hoặc',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink4),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.line)),
        ],
      ),
    );
  }
}

class _ZaloButton extends StatelessWidget {
  const _ZaloButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        backgroundColor: AppColors.paper,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0068FF),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'Z',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tiếp tục với Zalo',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        backgroundColor: AppColors.paper,
      ),
      onPressed: null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(
            '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''',
            width: 18,
            height: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'Tiếp tục với Google',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
