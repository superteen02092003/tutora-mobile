import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
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
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    await ref
        .read(forgotControllerProvider.notifier)
        .send(email: _emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forgotControllerProvider, (_, state) {
      if (state is ForgotSuccess) {
        setState(() => _sent = true);
      }
      if (state is ForgotError) {
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
                child: _sent
                    ? _SuccessView(
                        email: _emailCtrl.text.trim(),
                        onClose: () => context.pop(),
                      )
                    : _FormView(
                        emailCtrl: _emailCtrl,
                        isLoading: isLoading,
                        onSend: _onSend,
                        onBack: () => context.pop(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.emailCtrl,
    required this.isLoading,
    required this.onSend,
    required this.onBack,
  });

  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
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
              TextSpan(text: 'Quên mật khẩu?\n', style: AppTextStyles.h2()),
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
          'Nhập email bạn đăng ký — Tutora sẽ gửi link\nđặt lại mật khẩu trong vài giây.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.ink3,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),

        AuthInput(
          label: 'Email đã đăng ký',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          hint: 'ten@email.com',
          enabled: !isLoading,
          onSubmitted: (_) {
            if (emailCtrl.text.trim().isNotEmpty) onSend();
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
          onPressed: isLoading || emailCtrl.text.trim().isEmpty ? null : onSend,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cream,
                  ),
                )
              : const Text('Gửi link đặt lại'),
        ),
        const SizedBox(height: 10),

        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: const StadiumBorder(),
            side: const BorderSide(color: AppColors.line, width: 1.5),
            foregroundColor: AppColors.ink,
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onPressed: isLoading ? null : onBack,
          child: const Text('Tôi nhớ ra rồi'),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email, required this.onClose});

  final String email;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.gold,
            size: 26,
          ),
        ),
        const SizedBox(height: 20),

        Text('Kiểm tra hộp thư!', style: AppTextStyles.h2()),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.ink3,
              height: 1.6,
            ),
            children: [
              const TextSpan(
                text: 'Chúng tôi đã gửi link đặt lại mật khẩu đến\n',
              ),
              TextSpan(
                text: email,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const TextSpan(
                text:
                    '\n\nLink sẽ hết hạn sau 1 giờ. Nếu không thấy email, hãy kiểm tra thư mục spam.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

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
          onPressed: onClose,
          child: const Text('Về trang đăng nhập'),
        ),
      ],
    );
  }
}
