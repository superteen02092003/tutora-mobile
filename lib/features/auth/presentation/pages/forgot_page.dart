import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _emailCtrl = TextEditingController();

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

  void _onSend() {
    AppToast.show(
      context,
      message: 'Tính năng đang được phát triển.',
      type: AppToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Phải khớp với cream2 để status bar area không lộ màu khác
      backgroundColor: AppColors.cream2,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
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
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      hint: 'ten@email.com',
                      onSubmitted: (_) => _onSend(),
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
                      onPressed: _emailCtrl.text.trim().isEmpty
                          ? null
                          : _onSend,
                      child: const Text('Gửi link đặt lại'),
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
                      onPressed: () => context.pop(),
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
