import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/login_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/services/push_token_service.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Thông báo khi tài khoản học sinh / phụ huynh đăng nhập vào app gia sư.
const tutorOnlyMessage =
    'Ứng dụng này dành cho gia sư. Vui lòng dùng web toptutor.ai.';

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
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthTopDeco(
                  showBrand: true,
                  hand: 'Rất vui gặp lại bạn',
                  title: 'Đăng nhập',
                  lead: Text('Chào mừng trở lại — hãy tiếp tục học.'),
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
                        label: 'Số điện thoại, email hoặc tên đăng nhập',
                        controller: _identifierCtrl,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        hint: '090..., email@example.com hoặc tên đăng nhập',
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12),

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
                            foregroundColor: TutorColors.ink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Quên mật khẩu?',
                            style: TutorType.action(color: TutorColors.ink3),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      CanvasCta(
                        label: 'Đăng nhập',
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading ? const _Spinner() : null,
                      ),

                      const SizedBox(height: 28),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: TutorColors.line,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: TutorType.rowSub().copyWith(fontSize: 14),
                            children: [
                              const TextSpan(text: 'Chưa có tài khoản? '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => context.push(AppRoutes.register),
                                  child: Text(
                                    'Đăng ký gia sư',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: TutorColors.ink,
                                      decoration: TextDecoration.underline,
                                      decorationColor: TutorColors.ink,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vòng xoay nhỏ trên nút khi đang gửi.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(strokeWidth: 2, color: TutorColors.ink3),
  );
}
